#!/usr/bin/env python3
"""
対話型AIエージェントスクリプト
チャット方式でTerraformコードを生成し、ファイルに保存します。

使用方法:
    python3 scripts/interactive_agent.py
"""

import os
import sys
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv

# 環境変数の読み込み
load_dotenv()

# プロジェクトルートを取得（このスクリプトの親ディレクトリ）
PROJECT_ROOT = Path(__file__).parent.parent

# simple_agent_templateをインポート
sys.path.insert(0, str(PROJECT_ROOT / "templates" / "ai_agents"))
try:
    from simple_agent_template import SimpleTerraformAgent
except ImportError:
    print("❌ エラー: simple_agent_template.pyが見つかりません")
    print("   パスを確認してください: templates/ai_agents/simple_agent_template.py")
    sys.exit(1)


class InteractiveAgent:
    """対話型AIエージェント"""
    
    def __init__(self):
        """エージェントの初期化"""
        try:
            self.agent = SimpleTerraformAgent()
            print("✅ AIエージェントが初期化されました")
        except Exception as e:
            print(f"❌ エラー: エージェントの初期化に失敗しました: {e}")
            sys.exit(1)
    
    def save_code(self, code: str, filename: Optional[str] = None, directory: str = "workspace/terraform") -> str:
        """
        生成されたコードをファイルに保存
        
        Args:
            code: 保存するコード
            filename: ファイル名（Noneの場合は自動生成）
            directory: 保存先ディレクトリ
        
        Returns:
            保存されたファイルのパス
        """
        # ディレクトリの作成
        save_dir = PROJECT_ROOT / directory
        save_dir.mkdir(parents=True, exist_ok=True)
        
        # ファイル名の決定
        if not filename:
            # デフォルトファイル名を生成
            import datetime
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"generated_{timestamp}.tf"
        
        # .tf拡張子がない場合は追加
        if not filename.endswith('.tf'):
            filename += '.tf'
        
        # ファイルパス
        filepath = save_dir / filename
        
        # ファイルに書き込み
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(code)
        
        return str(filepath)
    
    def chat(self):
        """対話型チャットループ"""
        print("\n" + "="*60)
        print("🤖 対話型AIエージェント - Terraformコード生成")
        print("="*60)
        print("\n自然言語で指示を入力してください。")
        print("例: 'ap-northeast-1リージョンにt3.microのEC2インスタンスを作成してください'")
        print("\nコマンド:")
        print("  - 'exit' または 'quit': 終了")
        print("  - 'help': ヘルプを表示")
        print("  - 'save <filename>': 最後に生成したコードを保存（ファイル名を指定）")
        print("-"*60)
        
        last_code = None
        last_result = None
        
        while True:
            try:
                # ユーザー入力
                user_input = input("\n💬 あなた: ").strip()
                
                if not user_input:
                    continue
                
                # 終了コマンド
                if user_input.lower() in ['exit', 'quit', 'q']:
                    print("\n👋 終了します。お疲れ様でした！")
                    break
                
                # ヘルプコマンド
                if user_input.lower() == 'help':
                    self._show_help()
                    continue
                
                # 保存コマンド
                if user_input.lower().startswith('save '):
                    if last_code:
                        filename = user_input[5:].strip()
                        filepath = self.save_code(last_code, filename)
                        print(f"✅ コードを保存しました: {filepath}")
                    else:
                        print("❌ 保存するコードがありません。先にコードを生成してください。")
                    continue
                
                # コード生成
                print("\n🔄 コード生成中...")
                try:
                    result = self.agent.generate_code(user_input)
                    last_code = result['code']
                    last_result = result
                    
                    print("\n✅ コード生成完了！")
                    print("\n" + "="*60)
                    print("生成されたコード:")
                    print("="*60)
                    print(last_code)
                    print("="*60)
                    
                    # 検証結果の表示
                    if last_result['validation']['errors']:
                        print("\n⚠️  エラー:")
                        for error in last_result['validation']['errors']:
                            print(f"  - {error}")
                    
                    if last_result['validation']['warnings']:
                        print("\n⚠️  警告:")
                        for warning in last_result['validation']['warnings']:
                            print(f"  - {warning}")
                    
                    # 保存の提案
                    print("\n💡 ヒント: 'save <filename>' でファイルに保存できます")
                    print("   例: save ec2_instance.tf")
                    
                except Exception as e:
                    print(f"\n❌ エラー: コード生成に失敗しました: {e}")
                    print("   もう一度試してください。")
                
            except KeyboardInterrupt:
                print("\n\n👋 終了します。お疲れ様でした！")
                break
            except EOFError:
                print("\n\n👋 終了します。お疲れ様でした！")
                break
    
    def _show_help(self):
        """ヘルプを表示"""
        print("\n" + "="*60)
        print("📖 ヘルプ")
        print("="*60)
        print("\n【使い方】")
        print("1. 自然言語でTerraformコード生成の指示を入力")
        print("2. 生成されたコードを確認")
        print("3. 'save <filename>' でファイルに保存")
        print("\n【例】")
        print("💬 あなた: ap-northeast-1リージョンにt3.microのEC2インスタンスを作成してください")
        print("💬 あなた: save ec2_instance.tf")
        print("\n【コマンド】")
        print("  exit / quit / q  : 終了")
        print("  help            : このヘルプを表示")
        print("  save <filename> : 最後に生成したコードを保存")
        print("\n【保存先】")
        print(f"  デフォルト: {PROJECT_ROOT / 'workspace' / 'terraform'}")
        print("="*60)


def main():
    """メイン処理"""
    # APIキーの確認
    if not os.getenv('GROQ_API_KEY'):
        print("❌ エラー: GROQ_API_KEYが設定されていません")
        print("\n環境変数を設定してください:")
        print("  export GROQ_API_KEY='gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'")
        print("\nまたは、.envファイルを作成して設定してください。")
        sys.exit(1)
    
    # 対話型エージェントの起動
    agent = InteractiveAgent()
    agent.chat()


if __name__ == "__main__":
    main()
