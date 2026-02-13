"""
シンプルなAIエージェントテンプレート
セッション0で使用する基本的なエージェント実装
"""

import os
import json
from typing import Dict, Optional
from dotenv import load_dotenv

# 環境変数の読み込み
load_dotenv()

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("Warning: OpenAI library not installed. Install with: pip install openai")


class SimpleTerraformAgent:
    """シンプルなTerraformコード生成エージェント"""
    
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-4"):
        """
        初期化
        
        Args:
            api_key: OpenAI APIキー（Noneの場合は環境変数から取得）
            model: 使用するモデル名
        """
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        if not self.api_key:
            raise ValueError("APIキーが設定されていません。環境変数OPENAI_API_KEYを設定するか、api_key引数を指定してください。")
        
        if OPENAI_AVAILABLE:
            self.client = OpenAI(api_key=self.api_key)
        else:
            raise ImportError("OpenAI library is required. Install with: pip install openai")
        
        self.model = model
    
    def generate_code(self, prompt: str, context: Optional[Dict] = None) -> Dict:
        """
        Terraformコードを生成
        
        Args:
            prompt: 自然言語の指示
            context: 追加のコンテキスト情報（AWSリソース情報など）
        
        Returns:
            生成されたコードと検証結果を含む辞書
        """
        # プロンプトの構築
        full_prompt = self._build_prompt(prompt, context)
        
        # LLM API呼び出し
        response = self._call_llm(full_prompt)
        
        # コードの抽出
        code = self._extract_code(response)
        
        # 基本的な検証
        validation = self._validate_code(code)
        
        return {
            'code': code,
            'validation': validation,
            'raw_response': response
        }
    
    def _build_prompt(self, instruction: str, context: Optional[Dict] = None) -> str:
        """プロンプトの構築"""
        prompt = f"""
以下の要件でTerraformコードを生成してください。

要件:
{instruction}
"""
        
        if context:
            prompt += f"""

既存のインフラ情報:
{json.dumps(context, indent=2, ensure_ascii=False)}
"""
        
        prompt += """

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める（必要に応じて）
- コメントを適切に追加
- ベストプラクティスに従う

コードのみを出力してください（説明は不要です）。
"""
        return prompt
    
    def _call_llm(self, prompt: str) -> str:
        """LLM APIの呼び出し"""
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "あなたはTerraformコード生成の専門家です。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=2000
            )
            return response.choices[0].message.content
        except Exception as e:
            raise RuntimeError(f"LLM API呼び出しエラー: {str(e)}")
    
    def _extract_code(self, response: str) -> str:
        """レスポンスからコードを抽出"""
        import re
        
        # ```terraform または ```hcl ブロックを抽出
        pattern = r'```(?:terraform|hcl)?\s*\n(.*?)\n```'
        match = re.search(pattern, response, re.DOTALL)
        
        if match:
            return match.group(1).strip()
        
        # コードブロックがない場合は全体を返す
        return response.strip()
    
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


def main():
    """使用例"""
    # エージェントの初期化
    agent = SimpleTerraformAgent()
    
    # コード生成
    instruction = """
    ap-northeast-1リージョンに、t3.microインスタンスタイプのEC2インスタンスを作成してください。
    セキュリティグループはSSH（ポート22）のみ許可し、Nameタグに"training-ec2"を設定してください。
    """
    
    result = agent.generate_code(instruction)
    
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


if __name__ == "__main__":
    main()
