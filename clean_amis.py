from datetime import datetime
from dateutil import parser
import boto3
import os

ACCOUNT_ID = os.environ["ACCOUNT_ID"]
DELETE_OLDER_THAN_DAYS = os.environ["DELETE_OLDER_THAN_DAYS"]
EXCLUSION_TAG = os.environ["EXCLUSION_TAG"]
TAG_FILTER = os.environ["TAG_FILTER"]


def lambda_handler(event, context):
    ec2 = boto3.ec2("ec2")
    response = ec2.describe_images(
        Filters=[
            {"Name": f"tag:{TAG_FILTER}", "Values": ["*"]},
            {"Name": "Owners", "Values": [ACCOUNT_ID]},
        ]
    )
    print("Total images with this tag " + str(len(response["Images"])))

    used_images = {instance.image_id for instance in ec2.instances.all()}

    deleted_images = 0
    for image in response["Images"]:
        if image in used_images:
            continue

        create_date = parser.parse(image["CreationDate"])
        time_between_creation = datetime.now().replace(
            tzinfo=None
        ) - create_date.replace(tzinfo=None)

        if time_between_creation.days > int(DELETE_OLDER_THAN_DAYS):
            for tag in image["Tags"]:
                if tag["Key"] == EXCLUSION_TAG and tag["Value"] != "True":
                    deleted_images += 1
                    print("Deleting " + image["ImageId"] + " " + image["Name"])
                    _ = ec2.deregister_image(ImageId=image["ImageId"])

    print("Number of images deleted " + str(deleted_images))
    return True


if __name__ == "__main__":
    lambda_handler("", "")
