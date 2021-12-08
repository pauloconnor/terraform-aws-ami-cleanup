from datetime import datetime
from dateutil import parser
import boto3
import os

ACCOUNT_ID = os.environ["ACCOUNT_ID"]
DELETE_OLDER_THAN_DAYS = os.environ["DELETE_OLDER_THAN_DAYS"]
EXCLUSION_TAG = os.getenv("EXCLUSION_TAG", "DONOTDELETE")


def lambda_handler(event, context):
    ec2 = boto3.client("ec2")
    response = ec2.describe_images(Owners=[ACCOUNT_ID])
    print("Total images " + str(len(response["Images"])))

    used_images = []
    existing_instances = ec2.describe_instances()
    for reservations in existing_instances["Reservations"]:
        for instances in reservations["Instances"]:
            if instances["ImageId"] not in used_images:
                used_images.append(instances["ImageId"])
    print(used_images)

    deleted_images = 0
    for image in response["Images"]:
        if image["ImageId"] in used_images:
            print(image["ImageId"] + "is in use")
            continue

        create_date = parser.parse(image["CreationDate"])
        time_between_creation = datetime.now().replace(
            tzinfo=None
        ) - create_date.replace(tzinfo=None)

        if time_between_creation.days > int(DELETE_OLDER_THAN_DAYS):
            if "Tags" in image:
                delete = True
                for tag in image["Tags"]:
                    if tag["Key"] == EXCLUSION_TAG:
                        delete = False
                if delete:
                    deleted_images += 1
                    print(
                        "Deleting %s %s, Created %s"
                        % (
                            image["ImageId"],
                            image["Name"],
                            image["CreationDate"],
                        )  # noqa: E501
                    )

                    # _ = ec2.deregister_image(ImageId=image["ImageId"])

    print("Number of images deleted " + str(deleted_images))
    return True


if __name__ == "__main__":
    lambda_handler("", "")
