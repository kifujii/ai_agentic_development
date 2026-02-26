#!/usr/bin/env python3
"""
セッション構成図の自動生成スクリプト

使い方:
  pip install diagrams
  python scripts/generate_diagrams.py

必要条件:
  - Python 3.8+
  - diagrams ライブラリ (pip install diagrams)
  - Graphviz (https://graphviz.org/download/)
"""

import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "docs", "images")


def session1_diagram():
    """Session 1: VPC + Subnet + EC2 構成図"""
    from diagrams import Cluster, Diagram
    from diagrams.aws.compute import EC2
    from diagrams.aws.network import (
        VPC,
        PublicSubnet,
        InternetGateway,
        RouteTable,
    )
    from diagrams.aws.security import IAMRole

    filepath = os.path.join(OUTPUT_DIR, "session1_target")
    with Diagram(
        "Session 1: VPC + EC2 構成",
        show=False,
        filename=filepath,
        direction="TB",
    ):
        internet = InternetGateway("Internet Gateway")

        with Cluster("VPC (10.0.0.0/16)"):
            rt = RouteTable("Route Table\n0.0.0.0/0 → IGW")

            with Cluster("Public Subnet (10.0.1.0/24)\nap-northeast-1a"):
                ec2 = EC2("EC2\nt3.micro\nAmazon Linux 2023")

        internet >> rt >> ec2


def session2_diagram():
    """Session 2: ALB + ECS + RDS 構成図"""
    from diagrams import Cluster, Diagram
    from diagrams.aws.compute import ECS, ECR
    from diagrams.aws.database import RDS
    from diagrams.aws.network import ALB

    filepath = os.path.join(OUTPUT_DIR, "session2_target")
    with Diagram(
        "Session 2: Web System 構成",
        show=False,
        filename=filepath,
        direction="TB",
    ):
        with Cluster("VPC (10.0.0.0/16)"):
            with Cluster("Public Subnets"):
                alb = ALB("ALB\nHTTP:80")

            with Cluster("Private Subnets"):
                ecs = ECS("ECS Fargate\nx2 Tasks")
                rds = RDS("RDS MySQL\ndb.t3.micro")

            ecr = ECR("ECR Repository")

        alb >> ecs >> rds
        ecr >> ecs


def session3_diagram():
    """Session 3: Ansible ワークフロー"""
    from diagrams import Cluster, Diagram, Edge
    from diagrams.aws.compute import EC2
    from diagrams.generic.compute import Rack
    from diagrams.onprem.iac import Ansible

    filepath = os.path.join(OUTPUT_DIR, "session3_target")
    with Diagram(
        "Session 3: Ansible ワークフロー",
        show=False,
        filename=filepath,
        direction="LR",
    ):
        with Cluster("Control Node (DevSpaces)"):
            ansible = Ansible("Ansible")

        with Cluster("Target (EC2)"):
            ec2 = EC2("EC2\nAmazon Linux 2023")

        ansible >> Edge(label="SSH") >> ec2


def session4_diagram():
    """Session 4: CloudWatch Agent 構成図"""
    from diagrams import Cluster, Diagram, Edge
    from diagrams.aws.compute import EC2
    from diagrams.aws.management import Cloudwatch
    from diagrams.aws.security import IAMRole

    filepath = os.path.join(OUTPUT_DIR, "session4_target")
    with Diagram(
        "Session 4: CloudWatch Agent 構成",
        show=False,
        filename=filepath,
        direction="LR",
    ):
        iam = IAMRole("IAM Role\nCloudWatchAgent\nServerPolicy")

        with Cluster("VPC"):
            ec2 = EC2("EC2\n+ CloudWatch Agent")

        cw = Cloudwatch("CloudWatch\nMetrics & Logs")

        iam >> ec2 >> Edge(label="メトリクス/ログ送信") >> cw


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Session 1: VPC + EC2 構成図を生成中...")
    session1_diagram()

    print("Session 2: Web System 構成図を生成中...")
    session2_diagram()

    print("Session 3: Ansible ワークフロー図を生成中...")
    session3_diagram()

    print("Session 4: CloudWatch Agent 構成図を生成中...")
    session4_diagram()

    print(f"\n✅ 画像が {OUTPUT_DIR}/ に生成されました。")
