"""Seed 3 projects, 8 technologies and 8 pipeline steps from existing course data.

Example: python backend/seed.py --stack portfolio-week13
"""
import argparse
import json
import pathlib
import boto3


def output_values(client, stack):
    data = client.describe_stacks(StackName=stack)["Stacks"][0]
    return {x["OutputKey"]: x["OutputValue"] for x in data.get("Outputs", [])}


def seed(data, mapping, region="ap-northeast-2"):
    ddb = boto3.resource("dynamodb", region_name=region)
    projects = ddb.Table(mapping["ProjectsTable"])
    skills = ddb.Table(mapping["SkillsTable"])
    links = ddb.Table(mapping["LinksTable"])
    steps = ddb.Table(mapping["StepsTable"])
    for project in data["projects"]:
        row = dict(project)
        techs = row.pop("skills", [])
        with projects.batch_writer() as writer:
            writer.put_item(Item=row)
        with links.batch_writer() as writer:
            for skill_id in techs:
                writer.put_item(Item={"project_id": project["project_id"], "skill_id": skill_id})
    with skills.batch_writer() as writer:
        for skill in data["skills"]:
            writer.put_item(Item=skill)
    with steps.batch_writer() as writer:
        for project_id, items in data["pipeline"].items():
            for step in items:
                writer.put_item(Item={"project_id": project_id, **step})
    return {"projects": len(data["projects"]), "skills": len(data["skills"]),
            "steps": sum(len(v) for v in data["pipeline"].values())}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--stack", default="portfolio-week13")
    parser.add_argument("--region", default="ap-northeast-2")
    parser.add_argument("--data", default="patch/public/data/portfolio.json")
    args = parser.parse_args()
    records = json.loads(pathlib.Path(args.data).read_text(encoding="utf-8"))
    cf = boto3.client("cloudformation", region_name=args.region)
    print(seed(records, output_values(cf, args.stack), args.region))
