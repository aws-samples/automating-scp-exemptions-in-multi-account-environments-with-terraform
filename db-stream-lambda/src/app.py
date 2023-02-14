#
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

from boto3.dynamodb.types import TypeDeserializer
from botocore.exceptions import ClientError
from botocore.exceptions import ParamValidationError
import boto3
import datetime
import logging
import os

"""
The purpose of this script is to read in a DynamoDB record, convert it to input parameters 
for executing an SSM automation document.
"""

# Setup Default Logger
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

try:
    SCP_EXEMPTION_DOCUMENT_NAME = os.environ.get(
        "SCP_EXEMPTION_DOCUMENT_NAME", ""
    )  # 'cldeng-scp-exemption-tag'
    if not SCP_EXEMPTION_DOCUMENT_NAME or not isinstance(
            SCP_EXEMPTION_DOCUMENT_NAME, str
    ):
        raise ValueError("SCP_EXEMPTION_DOCUMENT_NAME is missing or invalid")

    CLEANUP_DOCUMENT_NAME = os.environ.get(
        "CLEANUP_DOCUMENT_NAME", ""
    )  # 'cldeng-scp-exemption-cleanup-v1'
    if not CLEANUP_DOCUMENT_NAME or not isinstance(
            CLEANUP_DOCUMENT_NAME, str
    ):
        raise ValueError("CLEANUP_DOCUMENT_NAME is missing or invalid")

    EXECUTION_ROLE_NAME = os.environ.get(
        "EXECUTION_ROLE_NAME", ""
    )  # 'cldeng-scp-exemption-ssm-automation-execution'
    if not EXECUTION_ROLE_NAME or not isinstance(
            EXECUTION_ROLE_NAME, str
    ):
        raise ValueError("EXECUTION_ROLE_NAME is missing or invalid")

    AUTOMATION_ASSUME_ROLE = os.environ.get(
        "AUTOMATION_ASSUME_ROLE", ""
    )  # 'arn:aws:iam::123456789012:role/cldeng-scp-iam-exemption-tagger-automation'
    if not AUTOMATION_ASSUME_ROLE or not isinstance(
            AUTOMATION_ASSUME_ROLE, str
    ):
        raise ValueError("AUTOMATION_ASSUME_ROLE is missing or invalid")

    LOG_LEVEL = os.environ.get("LOG_LEVEL", "DEBUG")
    if isinstance(LOG_LEVEL, str):
        log_level = logging.getLevelName(LOG_LEVEL.upper())
        logger.setLevel(log_level)
    else:
        raise ValueError("LOG_LEVEL is not a string")

    MAX_CONCURRENCY = "10"
    MAX_ERRORS = "25%"
    SSM_CLIENT = boto3.client("ssm")
except Exception as e:
    logger.error(f"Initialization Exception: {e}")
    raise


def deserialize(record):
    """
    Deserialize a DynamoDB record into a python dictionary
    :param record: DynamoDB record
    :return: Deserialized record
    """
    deserializer = TypeDeserializer()

    if isinstance(record, list):
        return [deserialize(v) for v in record]

    if isinstance(record, dict):
        try:
            return deserializer.deserialize(record)
        except TypeError:
            return {k: deserialize(v) for k, v in record.items()}
    else:
        return record


def start_cleanup_automation_execution(record):
    """
    Start an automation document with provided parameters
    :param record: parameters required to execute the automation document
    :return: None
    """
    try:
        new_image = record["dynamodb"]["NewImage"]
        table_name = record["eventSourceARN"].split('/')[1]

        if new_image.get("ttl"):
            account_id = new_image["AccountId"]
            role_name = new_image["RoleName"]
            ttl = new_image["ttl"]
            dt = datetime.datetime.utcfromtimestamp(int(ttl))
            iso_format = dt.isoformat() + 'Z'

            SSM_CLIENT.start_automation_execution(
                DocumentName=CLEANUP_DOCUMENT_NAME,
                DocumentVersion="$DEFAULT",
                Parameters={
                    "DynamoDBTableName": [table_name],
                    "WaitTimeStamp": [iso_format],
                    "PrimaryKey": [account_id],
                    "SortKey": [role_name],
                    "automationAssumeRole": [AUTOMATION_ASSUME_ROLE],
                },
                Mode="Auto"
            )
    except ClientError as ce:
        logger.error(f"Client Error starting cleanup automation execution: {ce}")
        raise
    except Exception as exc:
        logger.error(f"Error starting automation execution: {exc}")
        raise


def start_tag_automation_execution(document_dict):
    """
    Start an automation document with provided parameters
    :param document_dict: parameters required to execute the automation document
    :return: AutomationExecutionId
    """
    try:
        response = SSM_CLIENT.start_automation_execution(
            DocumentName=SCP_EXEMPTION_DOCUMENT_NAME,
            DocumentVersion="$DEFAULT",
            Parameters=document_dict["parameters"],
            Mode="Auto",
            TargetLocations=[
                {
                    "Accounts": [document_dict["account_id"]],
                    "Regions": [
                        "us-east-1",
                    ],
                    "TargetLocationMaxConcurrency": MAX_CONCURRENCY,
                    "TargetLocationMaxErrors": MAX_ERRORS,
                    "ExecutionRoleName": EXECUTION_ROLE_NAME,
                },
            ],
        )

        return response["AutomationExecutionId"]

    except ParamValidationError as pve:
        logger.error(f"Parameter Validation Error: {pve}")
    except ClientError as ce:
        logger.error(f"Client Error starting automation execution: {ce}")
        raise
    except Exception as exc:
        logger.error(f"Error starting automation execution: {exc}")
        raise


def create_document_dict(record):
    """
    Populate the document dictionary values with the DynamoDB record
    :param record: DynamoDB record
    :return: Document dictionary
    """
    document_dict = {}
    try:
        event_name = record.get("eventName")

        if event_name == "INSERT":  # MODIFY IGNORED
            new_image = record["dynamodb"]["NewImage"]

            if (
                    new_image.get("AccountId")
                    and new_image.get("RoleName")
                    and new_image.get("ExemptionTagKeys")
            ):
                document_dict["account_id"] = new_image["AccountId"]
                document_dict["parameters"] = {
                    "RoleName": [new_image["RoleName"]],
                    "ExemptionTagKeys": new_image["ExemptionTagKeys"],
                    "TagUntag": ["Tag"],
                    "automationAssumeRole": [AUTOMATION_ASSUME_ROLE],
                }
        elif event_name == "REMOVE":
            old_image = record["dynamodb"]["OldImage"]

            if (
                    old_image.get("AccountId")
                    and old_image.get("RoleName")
                    and old_image.get("ExemptionTagKeys")
            ):
                document_dict["account_id"] = old_image["AccountId"]
                document_dict["parameters"] = {
                    "RoleName": [old_image["RoleName"]],
                    "ExemptionTagKeys": old_image["ExemptionTagKeys"],
                    "TagUntag": ["Untag"],
                    "automationAssumeRole": [AUTOMATION_ASSUME_ROLE],
                }
        return document_dict
    except KeyError as ke:
        logger.error(f"Key Error: {ke}")
        raise
    except Exception as exc:
        logger.error(f"Error processing record: {exc}")
        raise


def lambda_handler(event, _):
    try:
        for record in event.get("Records"):
            logger.info(f"Event ID: {record.get('eventID')}")
            logger.info(f"Event Name: {record.get('eventName')}")
            logger.info(f'Record {record}')

            deserialized_record = deserialize(record)
            logger.debug(f"Deserialized Record: {deserialized_record}")

            document_dict = create_document_dict(deserialized_record)
            logger.debug(f"Document Dict: {document_dict}")

            if document_dict:
                logger.info("Starting Automation...")
                execution_id = start_tag_automation_execution(document_dict)
                logger.info(f"Automation Started {execution_id}")

                if record.get("eventName", "") == "INSERT":
                    start_cleanup_automation_execution(deserialized_record)
            else:
                logger.info(
                    "Record not processed since it did not contain AccountId, RoleName, "
                    "and ExemptionTags or was Modified"
                )
    except Exception as error:
        logger.error(f"lambda_handler - {error}")
        raise
