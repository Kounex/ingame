from scripts.release import stack_version
from scripts.release.stack_version import (
    normalize_release_tag,
    read_pubspec_semver,
    cmd_prepare_release,
    sync_chart_versions,
    sync_fastapi_version,
    sync_api_values_image_refs,
    sync_web_values_image_refs,
)


def test_read_pubspec_semver_strips_build_number():
    content = "name: ingame\nversion: 0.2.3+7\n"

    assert read_pubspec_semver(content) == "0.2.3"


def test_normalize_release_tag_requires_v_prefix():
    assert normalize_release_tag("v1.2.3") == "1.2.3"


def test_sync_fastapi_version_updates_literal():
    source = 'app = FastAPI(title="InGame API", version="0.1.0")\n'

    updated = sync_fastapi_version(source, "0.2.0")

    assert 'version="0.2.0"' in updated


def test_sync_chart_versions_updates_chart_and_app_versions():
    source = 'apiVersion: v2\nversion: 0.1.0\nappVersion: "0.1.0"\n'

    updated = sync_chart_versions(source, "0.3.1")

    assert "version: 0.3.1" in updated
    assert 'appVersion: "0.3.1"' in updated


def test_sync_api_values_image_refs_updates_repository_and_tag():
    source = """image:
  repository: ingame-api
  tag: latest
"""

    updated = sync_api_values_image_refs(source, owner="Kounex", version="0.4.0")

    assert "repository: ghcr.io/kounex/ingame-api" in updated
    assert "tag: 0.4.0" in updated


def test_sync_web_values_image_refs_updates_repository_and_tag():
    source = """image:
  repository: ingame-web
  tag: latest
"""

    updated = sync_web_values_image_refs(source, owner="Kounex", version="0.4.0")

    assert "repository: ghcr.io/kounex/ingame-web" in updated
    assert "tag: 0.4.0" in updated


def test_prepare_release_syncs_backend_chart_and_values(tmp_path, monkeypatch):
    pubspec = tmp_path / "pubspec.yaml"
    backend = tmp_path / "main.py"
    api_chart = tmp_path / "api-chart.yaml"
    web_chart = tmp_path / "web-chart.yaml"
    api_values = tmp_path / "api-values.yaml"
    web_values = tmp_path / "web-values.yaml"

    pubspec.write_text("name: ingame\nversion: 0.5.0+9\n")
    backend.write_text('app = FastAPI(version="0.1.0")\n')
    api_chart.write_text('apiVersion: v2\nversion: 0.1.0\nappVersion: "0.1.0"\n')
    web_chart.write_text('apiVersion: v2\nversion: 0.1.0\nappVersion: "0.1.0"\n')
    api_values.write_text(
        "image:\n"
        "  repository: ingame-api\n"
        "  tag: latest\n"
    )
    web_values.write_text(
        "image:\n"
        "  repository: ingame-web\n"
        "  tag: latest\n"
    )

    monkeypatch.setattr(stack_version, "PUBSPEC_PATH", pubspec)
    monkeypatch.setattr(stack_version, "BACKEND_MAIN_PATH", backend)
    monkeypatch.setattr(stack_version, "API_HELM_CHART_PATH", api_chart)
    monkeypatch.setattr(stack_version, "WEB_HELM_CHART_PATH", web_chart)
    monkeypatch.setattr(stack_version, "API_HELM_VALUES_PATH", api_values)
    monkeypatch.setattr(stack_version, "WEB_HELM_VALUES_PATH", web_values)

    assert cmd_prepare_release(owner="Kounex", write=True) == 0
    assert read_pubspec_semver(pubspec.read_text()) == "0.5.0"
    assert 'version="0.5.0"' in backend.read_text()
    assert 'appVersion: "0.5.0"' in api_chart.read_text()
    assert 'appVersion: "0.5.0"' in web_chart.read_text()
    assert "repository: ghcr.io/kounex/ingame-api" in api_values.read_text()
    assert "repository: ghcr.io/kounex/ingame-web" in web_values.read_text()
    assert "tag: 0.5.0" in api_values.read_text()
    assert "tag: 0.5.0" in web_values.read_text()
