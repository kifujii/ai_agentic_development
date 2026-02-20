"""
シンプルなAIエージェントテンプレート
セッション1で使用する基本的なエージェント実装

このエージェントは、Continue（AWS Bedrock）を使用することを前提としています。
ContinueはVS Code拡張機能として動作するため、このテンプレートは
Continueとの連携方法を示すためのものです。

実際の実装では、ContinueのAPIを直接呼び出すのではなく、
Continueのチャット機能を使用してコード生成を行います。
"""

import os
import json
import boto3
from typing import Dict, Optional, List
from dotenv import load_dotenv

# 環境変数の読み込み
load_dotenv()


class SimpleTerraformAgent:
    """
    シンプルなTerraformコード生成エージェント
    
    このエージェントは、Continue（AWS Bedrock）を使用してTerraformコードを生成します。
    プロンプト改善、不足パラメータの聞き返し、Context Engineering、フィードバックループ機能を実装しています。
    """
    
    def __init__(self, aws_region: str = "us-east-1"):
        """
        初期化
        
        Args:
            aws_region: AWSリージョン（デフォルト: us-east-1）
        """
        self.aws_region = aws_region
        self.bedrock_client = boto3.client('bedrock-runtime', region_name=aws_region)
        self.context_manager = ContextManager(aws_region)
    
    def generate_code(self, instruction: str, context: Optional[Dict] = None, require_approval: bool = True) -> Dict:
        """
        Terraformコードを生成（承認ワークフロー付き）
        
        Args:
            instruction: 自然言語の指示
            context: 追加のコンテキスト情報（AWSリソース情報など）
            require_approval: 承認ワークフローを要求するか
        
        Returns:
            生成されたコードと検証結果を含む辞書
        """
        # 1. プロンプトの改善
        improved_prompt = self.improve_prompt(instruction)
        
        # 2. 不足パラメータのチェック
        missing_params = self.check_missing_parameters(improved_prompt)
        if missing_params:
            print(f"以下のパラメータが不足しています: {missing_params}")
            print("これらの値を指定してください。")
            # 実際の実装では、Continueに質問を返す
            return {'error': 'missing_parameters', 'missing': missing_params}
        
        # 3. Context Engineering（コンテキストの取得）
        if context is None:
            context = self.context_manager.get_aws_context()
        
        # 4. プロンプトの構築
        full_prompt = self._build_prompt(improved_prompt, context)
        
        # 5. 承認ワークフロー
        if require_approval:
            plan = self.create_plan(full_prompt)
            if not plan:
                return {'error': 'user_rejected', 'message': 'ユーザーが実行を拒否しました'}
        
        # 6. Continueを使用したコード生成
        # 注意: 実際の実装では、Continueのチャット機能を使用します
        # このテンプレートでは、Continueの使用方法を示すためのコメントを追加
        code = self._generate_with_continue(full_prompt)
        
        # 7. 基本的な検証
        validation = self._validate_code(code)
        
        # 8. エラー修正プロセス
        if not validation['valid']:
            fix_proposal = self.propose_fix(validation['errors'], code)
            if fix_proposal:
                approval = input("修正を適用しますか？ (y/n): ")
                if approval.lower() == 'y':
                    code = self.apply_fix(fix_proposal, code)
                    validation = self._validate_code(code)
        
        return {
            'code': code,
            'validation': validation,
            'prompt': full_prompt
        }
    
    def improve_prompt(self, instruction: str) -> str:
        """
        プロンプトの改善
        
        Args:
            instruction: 元の指示
        
        Returns:
            改善されたプロンプト
        """
        # 基本的なプロンプト改善ルールを適用
        improved = instruction
        
        # 「足りていないパラメータがある場合は聞き返してください」を追加
        if "足りていないパラメータ" not in improved and "聞き返してください" not in improved:
            improved += "\n\n注意事項:\n- 足りていないパラメータなどがある場合は、そのまま構築するのではなく一度聞き返してください"
        
        # ベストプラクティスの指示を追加
        if "ベストプラクティス" not in improved:
            improved += "\n- ベストプラクティスに従ってください"
        
        return improved
    
    def check_missing_parameters(self, prompt: str) -> List[str]:
        """
        不足パラメータのチェック
        
        Args:
            prompt: プロンプト
        
        Returns:
            不足しているパラメータのリスト
        """
        # 基本的な必須パラメータ
        required_params = {
            'EC2': ['リージョン', 'インスタンスタイプ', 'AMI'],
            'VPC': ['CIDRブロック'],
            'S3': ['バケット名']
        }
        
        missing = []
        # 実際の実装では、より高度なパラメータチェックを実装
        # ここでは簡易的な実装を示す
        
        return missing
    
    def create_plan(self, prompt: str) -> Optional[Dict]:
        """
        実行計画を作成して人間の承認を求める（承認ワークフロー）
        
        Args:
            prompt: プロンプト
        
        Returns:
            承認された計画、またはNone（拒否された場合）
        """
        print("実行計画:")
        print("=" * 50)
        print(prompt)
        print("=" * 50)
        approval = input("実行しますか？ (y/n): ")
        if approval.lower() == 'y':
            return {'approved': True, 'prompt': prompt}
        return None
    
    def propose_fix(self, errors: List[str], code: str) -> Optional[str]:
        """
        エラーに対する修正提案（エラー修正プロセス）
        
        Args:
            errors: エラーリスト
            code: 元のコード
        
        Returns:
            修正提案、またはNone
        """
        print(f"エラー: {errors}")
        # 実際の実装では、Continueに修正を依頼
        # ここでは簡易的な修正提案を示す
        fix_proposal = f"以下のエラーを修正してください:\n{chr(10).join(errors)}"
        return fix_proposal
    
    def apply_fix(self, fix_proposal: str, code: str) -> str:
        """
        修正を適用
        
        Args:
            fix_proposal: 修正提案
            code: 元のコード
        
        Returns:
            修正されたコード
        """
        # 実際の実装では、Continueに修正を依頼
        # ここでは簡易的な実装を示す
        return code
    
    def improve_code(self, code: str, feedback: str) -> str:
        """
        人間のフィードバックに基づいてコードを改善（反復的改善）
        
        Args:
            code: 元のコード
            feedback: 人間のフィードバック
        
        Returns:
            改善されたコード
        """
        # 実際の実装では、Continueに改善を依頼
        # ここでは簡易的な実装を示す
        improved_prompt = f"{code}\n\n以下のフィードバックに基づいて改善してください:\n{feedback}"
        return self._generate_with_continue(improved_prompt)
    
    def _build_prompt(self, instruction: str, context: Optional[Dict] = None) -> str:
        """プロンプトの構築"""
        prompt = f"""
下記条件を満たすTerraformコードを生成してください。

要件:
{instruction}
"""
        
        if context:
            prompt += f"""

既存のインフラ情報:
{json.dumps(context, indent=2, ensure_ascii=False)}

上記の情報を考慮して、既存のリソースと衝突しないように注意してください。
"""
        
        prompt += """

出力形式:
- HCL形式のTerraformコード
- 変数定義を含めてください
- コメントを適切に追加してください
- ベストプラクティスに従ってください

コードのみを出力してください（説明は不要です）。
"""
        return prompt
    
    def _generate_with_continue(self, prompt: str) -> str:
        """
        Continueを使用したコード生成
        
        注意: 実際の実装では、Continueのチャット機能を使用します。
        このメソッドは、Continueの使用方法を示すためのプレースホルダーです。
        
        Args:
            prompt: プロンプト
        
        Returns:
            生成されたコード
        """
        # 実際の実装では、ContinueのAPIを使用
        # または、Continueのチャット機能を使用してコード生成
        # ここでは、Continueの使用方法を示すコメントを追加
        
        print("=" * 50)
        print("Continueを使用してコード生成を行います")
        print("=" * 50)
        print("Continueを起動（Ctrl+L / Cmd+L）して、以下のプロンプトを入力してください:")
        print("-" * 50)
        print(prompt)
        print("-" * 50)
        print("生成されたコードをコピーして、このメソッドの戻り値として使用してください")
        
        # 実際の実装では、ContinueのAPIを使用してコード生成
        # または、ユーザーがContinueで生成したコードを入力
        code = input("生成されたコードを貼り付けてください（空行で終了）:\n")
        return code
    
    
    def _validate_code(self, code: str) -> Dict:
        """コードの基本的な検証"""
        validation = {
            'valid': True,
            'errors': [],
            'warnings': []
        }
        
        # 基本的な構文チェック
        if not code:
            validation['valid'] = False
            validation['errors'].append('コードが空です')
        
        # Terraformのキーワードチェック
        required_keywords = ['resource', 'provider', 'variable']
        found_keywords = [kw for kw in required_keywords if kw in code]
        
        if not found_keywords:
            validation['warnings'].append('Terraformの主要キーワードが見つかりません')
        
        return validation


class ContextManager:
    """コンテキスト管理クラス"""
    
    def __init__(self, aws_region: str = "us-east-1"):
        """
        初期化
        
        Args:
            aws_region: AWSリージョン
        """
        self.aws_region = aws_region
        self.ec2_client = boto3.client('ec2', region_name=aws_region)
    
    def get_aws_context(self) -> Dict:
        """
        AWSリソース情報を取得してコンテキスト化
        
        Returns:
            AWSリソース情報の辞書
        """
        try:
            # 既存のVPC情報
            vpcs = self.ec2_client.describe_vpcs()
            
            # 既存のサブネット情報
            subnets = self.ec2_client.describe_subnets()
            
            # 既存のセキュリティグループ情報
            security_groups = self.ec2_client.describe_security_groups()
            
            # 利用可能な可用性ゾーン
            azs = self.ec2_client.describe_availability_zones()
            
            return {
                'existing_vpcs': [vpc['VpcId'] for vpc in vpcs['Vpcs']],
                'existing_subnets': [subnet['SubnetId'] for subnet in subnets['Subnets']],
                'existing_security_groups': [sg['GroupId'] for sg in security_groups['SecurityGroups']],
                'available_azs': [az['ZoneName'] for az in azs['AvailabilityZones']],
                'current_region': self.aws_region
            }
        except Exception as e:
            print(f"警告: AWSリソース情報の取得に失敗しました: {e}")
            return {
                'existing_vpcs': [],
                'existing_subnets': [],
                'existing_security_groups': [],
                'available_azs': [],
                'current_region': self.aws_region
            }
    
    def check_resource_conflicts(self, new_resource: Dict, existing_resources: Dict) -> List[str]:
        """
        リソース間の整合性チェック
        
        Args:
            new_resource: 新しいリソース情報
            existing_resources: 既存のリソース情報
        
        Returns:
            衝突しているリソースのリスト
        """
        conflicts = []
        
        # リソース名の重複チェック
        if 'name' in new_resource:
            # 実際の実装では、既存リソース名と比較
            pass
        
        # CIDRブロックの衝突チェック
        if 'cidr' in new_resource:
            # 実際の実装では、既存CIDRブロックと比較
            pass
        
        return conflicts


def main():
    """使用例"""
    # エージェントの初期化
    agent = SimpleTerraformAgent(aws_region="ap-northeast-1")
    
    # コード生成（承認ワークフロー付き）
    instruction = """
    ap-northeast-1リージョンに、t3.microインスタンスタイプのEC2インスタンスを作成してください。
    セキュリティグループはSSH（ポート22）のみ許可し、Nameタグに"training-ec2"を設定してください。
    """
    
    result = agent.generate_code(instruction, require_approval=True)
    
    if 'error' in result:
        print(f"エラー: {result['error']}")
        if 'missing' in result:
            print(f"不足パラメータ: {result['missing']}")
        return
    
    print("生成されたコード:")
    print("=" * 50)
    print(result['code'])
    print("=" * 50)
    
    print("\n検証結果:")
    print(f"有効: {result['validation']['valid']}")
    if result['validation']['errors']:
        print(f"エラー: {result['validation']['errors']}")
    if result['validation']['warnings']:
        print(f"警告: {result['validation']['warnings']}")
    
    # 反復的改善の例
    feedback = input("\nコードを改善したい点があれば入力してください（Enterでスキップ）: ")
    if feedback:
        improved_code = agent.improve_code(result['code'], feedback)
        print("\n改善されたコード:")
        print("=" * 50)
        print(improved_code)
        print("=" * 50)


if __name__ == "__main__":
    main()
