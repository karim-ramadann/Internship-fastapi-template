"""
S3 service for uploading and downloading data from AWS S3.
"""

import json
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import ClientError

from app.core.config import settings


class S3Service:
    """Handles S3 operations for the RAG pipeline."""

    def __init__(
        self,
        bucket: str | None = None,
        region: str | None = None,
    ) -> None:
        self.bucket = bucket or settings.S3_BUCKET
        self.region = region or settings.AWS_REGION
        self._client: Any = None

    @property
    def client(self) -> Any:
        """Lazy-loaded S3 client."""
        if self._client is None:
            self._client = boto3.client("s3", region_name=self.region)
        return self._client

    def upload_file(self, local_path: Path | str, s3_key: str | None = None) -> str:
        """Upload a file to S3. Returns the S3 URI."""
        path = Path(local_path)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {local_path}")

        s3_key = s3_key or path.name
        self._ensure_bucket_exists()
        self.client.upload_file(str(path), self.bucket, s3_key)

        return f"s3://{self.bucket}/{s3_key}"

    def upload_json(self, data: dict, s3_key: str) -> str:
        """Upload a JSON dict directly to S3. Returns the S3 URI."""
        self._ensure_bucket_exists()
        self.client.put_object(
            Bucket=self.bucket,
            Key=s3_key,
            Body=json.dumps(data, ensure_ascii=False, default=str),
            ContentType="application/json",
        )
        return f"s3://{self.bucket}/{s3_key}"

    def download_json(self, s3_key: str) -> dict:
        """Download and parse a JSON object from S3."""
        response = self.client.get_object(Bucket=self.bucket, Key=s3_key)
        content = response["Body"].read().decode("utf-8")
        return json.loads(content)  # type: ignore[no-any-return]

    def _ensure_bucket_exists(self) -> None:
        """Create the S3 bucket if it doesn't exist."""
        try:
            self.client.head_bucket(Bucket=self.bucket)
        except ClientError as e:
            if e.response["Error"]["Code"] == "404":
                self.client.create_bucket(
                    Bucket=self.bucket,
                    CreateBucketConfiguration={
                        "LocationConstraint": self.region,
                    },
                )
            else:
                raise
