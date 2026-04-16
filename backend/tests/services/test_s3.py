"""Tests for the S3 service."""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import ClientError

from app.services.bedrock.s3 import S3Service


class TestS3Service:
    """Tests for S3Service."""

    def _make_service(self) -> S3Service:
        """Create an S3Service with a mocked client."""
        service = S3Service(bucket="test-bucket", region="us-east-1")
        service._client = MagicMock()
        return service

    def test_upload_file_success(self, tmp_path: Path) -> None:
        """Test uploading a file to S3."""
        service = self._make_service()
        test_file = tmp_path / "data.json"
        test_file.write_text('{"key": "value"}')

        result = service.upload_file(test_file, "data.json")

        assert result == "s3://test-bucket/data.json"
        service.client.upload_file.assert_called_once_with(
            str(test_file), "test-bucket", "data.json"
        )

    def test_upload_file_default_key(self, tmp_path: Path) -> None:
        """Test that s3_key defaults to filename."""
        service = self._make_service()
        test_file = tmp_path / "myfile.json"
        test_file.write_text("{}")

        result = service.upload_file(test_file)

        assert result == "s3://test-bucket/myfile.json"

    def test_upload_file_not_found(self) -> None:
        """Test that missing file raises FileNotFoundError."""
        service = self._make_service()

        with pytest.raises(FileNotFoundError):
            service.upload_file("/nonexistent/file.json")

    def test_upload_json(self) -> None:
        """Test uploading JSON data directly."""
        service = self._make_service()
        data = {"pages": [{"url": "https://example.com"}]}

        result = service.upload_json(data, "output/data.json")

        assert result == "s3://test-bucket/output/data.json"
        service.client.put_object.assert_called_once()
        call_kwargs = service.client.put_object.call_args[1]
        assert call_kwargs["Bucket"] == "test-bucket"
        assert call_kwargs["Key"] == "output/data.json"
        assert json.loads(call_kwargs["Body"]) == data

    def test_download_json(self) -> None:
        """Test downloading and parsing JSON from S3."""
        service = self._make_service()
        data = {"key": "value"}
        body_mock = MagicMock()
        body_mock.read.return_value = json.dumps(data).encode("utf-8")
        service.client.get_object.return_value = {"Body": body_mock}

        result = service.download_json("data.json")

        assert result == data
        service.client.get_object.assert_called_once_with(
            Bucket="test-bucket", Key="data.json"
        )

    def test_ensure_bucket_exists_already_exists(self) -> None:
        """Test that existing bucket is not recreated."""
        service = self._make_service()

        service._ensure_bucket_exists()

        service.client.head_bucket.assert_called_once_with(Bucket="test-bucket")
        service.client.create_bucket.assert_not_called()

    def test_ensure_bucket_creates_when_missing(self) -> None:
        """Test that missing bucket is created."""
        service = self._make_service()
        error_response = {"Error": {"Code": "404"}}
        service.client.head_bucket.side_effect = ClientError(
            error_response, "HeadBucket"
        )

        service._ensure_bucket_exists()

        service.client.create_bucket.assert_called_once()

    def test_ensure_bucket_raises_on_other_error(self) -> None:
        """Test that non-404 errors are re-raised."""
        service = self._make_service()
        error_response = {"Error": {"Code": "403"}}
        service.client.head_bucket.side_effect = ClientError(
            error_response, "HeadBucket"
        )

        with pytest.raises(ClientError):
            service._ensure_bucket_exists()

    def test_lazy_client_creation(self) -> None:
        """Test that boto3 client is created lazily."""
        with patch("app.services.bedrock.s3.boto3") as mock_boto3:
            service = S3Service(bucket="test-bucket", region="us-east-1")
            assert service._client is None

            _ = service.client
            mock_boto3.client.assert_called_once_with("s3", region_name="us-east-1")
