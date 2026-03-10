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
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "docs", "images")


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
        with Cluster("Control Node (VSCode)"):
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


def main():
    try:
        from diagrams import Diagram  # noqa: F401
    except ImportError:
        print(
            "エラー: diagrams ライブラリが見つかりません。\n"
            "  pip install diagrams\n"
            "また、Graphviz もインストールされている必要があります。\n"
            "  https://graphviz.org/download/",
            file=sys.stderr,
        )
        sys.exit(1)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    generators = [
        ("Session 1: VPC + EC2 構成図", session1_diagram),
        ("Session 2: Web System 構成図", session2_diagram),
        ("Session 3: Ansible ワークフロー図", session3_diagram),
        ("Session 4: CloudWatch Agent 構成図", session4_diagram),
    ]

    failed = []
    for label, func in generators:
        print(f"{label}を生成中...")
        try:
            func()
        except Exception as e:
            print(f"  ⚠ {label}の生成に失敗しました: {e}", file=sys.stderr)
            failed.append(label)

    if failed:
        print(f"\n⚠ {len(failed)} 件の図の生成に失敗しました:", file=sys.stderr)
        for name in failed:
            print(f"  - {name}", file=sys.stderr)
        sys.exit(1)

    print(f"\n✅ 画像が {OUTPUT_DIR}/ に生成されました。")


if __name__ == "__main__":
    main()
