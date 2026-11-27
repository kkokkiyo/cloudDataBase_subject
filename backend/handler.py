"""13주차 Project API: read-only HTTP API -> Lambda -> DynamoDB."""
import json
import logging
import os
from decimal import Decimal
from urllib.parse import unquote

import boto3
from boto3.dynamodb.conditions import Key

LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)
dynamodb = boto3.resource("dynamodb")


def table(env_name):
    return dynamodb.Table(os.environ[env_name])


def scan_items(tab):
    items = []
    arguments = {}
    while True:
        data = tab.scan(**arguments)
        items.extend(data.get("Items", []))
        if "LastEvaluatedKey" not in data:
            break
        arguments["ExclusiveStartKey"] = data["LastEvaluatedKey"]
    return items


def query_items(tab, **arguments):
    items = []
    while True:
        result = tab.query(**arguments)
        items.extend(result.get("Items", []))
        if "LastEvaluatedKey" not in result:
            break
        arguments["ExclusiveStartKey"] = result["LastEvaluatedKey"]
    return items


def encode_decimal(value):
    if isinstance(value, Decimal):
        return int(value) if value == int(value) else float(value)
    raise TypeError("Unsupported value type")


def reply(code, payload):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store"},
        "body": json.dumps(payload, ensure_ascii=False, default=encode_decimal)
    }


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", event.get("httpMethod", "GET"))
    path = (event.get("rawPath") or event.get("path") or "/").rstrip("/") or "/"
    if method != "GET":
        return reply(405, {"error": "Method not allowed"})
    try:
        projects = table("PROJECTS_TABLE")
        skills = table("SKILLS_TABLE")
        edges = table("LINKS_TABLE")
        steps = table("STEPS_TABLE")
        if path == "/projects":
            results = scan_items(projects)
            results.sort(key=lambda p: p.get("period", ""), reverse=True)
            return reply(200, {"projects": results})
        if path == "/graph":
            selection = (event.get("queryStringParameters") or {}).get("skill_id")
            if selection and len(selection) > 80:
                return reply(400, {"error": "Invalid skill_id"})
            links = (query_items(edges, IndexName="skill_id-index", KeyConditionExpression=Key("skill_id").eq(selection))
                     if selection else scan_items(edges))
            return reply(200, {"skills": scan_items(skills), "edges": links})
        segments = [unquote(s) for s in path.strip("/").split("/")]
        if len(segments) == 2 and segments[0] == "projects":
            record = projects.get_item(Key={"project_id": segments[1]}).get("Item")
            return reply(200, {"project": record}) if record else reply(404, {"error": "Project not found"})
        if len(segments) == 3 and segments[0] == "projects" and segments[2] == "pipeline":
            result = query_items(steps, KeyConditionExpression=Key("project_id").eq(segments[1]), ScanIndexForward=True)
            return reply(200, {"project_id": segments[1], "steps": result})
        return reply(404, {"error": "Route not found"})
    except Exception:
        LOG.exception("Unexpected read API failure")
        return reply(500, {"error": "Internal server error"})
