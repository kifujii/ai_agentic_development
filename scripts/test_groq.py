#!/usr/bin/env python3
"""
Groq API接続テストスクリプト

このスクリプトは、Groq APIが正しく設定されているか確認します。
使用方法:
    python3 scripts/test_groq.py
"""

import os
import sys

def main():
    """Groq API接続テストのメイン処理"""
    
    # APIキーを環境変数から取得
    api_key = os.getenv("GROQ_API_KEY")
    
    if not api_key:
        print("❌ エラー: GROQ_API_KEYが設定されていません")
        print("\n環境変数を設定してください:")
        print("  export GROQ_API_KEY='gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'")
        print("\nまたは、永続的に設定する場合:")
        print("  echo 'export GROQ_API_KEY=\"gsk_...\"' >> ~/.bashrc")
        print("  source ~/.bashrc")
        sys.exit(1)
    
    # groqモジュールのインポート確認
    try:
        from groq import Groq
    except ImportError:
        print("❌ エラー: groqモジュールがインストールされていません")
        print("\ngroqモジュールをインストールしてください:")
        print("  pip3 install --user groq")
        print("\nまたは、requirements.txtからすべてのパッケージをインストール:")
        print("  pip3 install --user -r requirements.txt")
        sys.exit(1)
    
    # Groqクライアントの初期化
    try:
        client = Groq(api_key=api_key)
    except Exception as e:
        print(f"❌ エラー: Groqクライアントの初期化に失敗しました: {e}")
        sys.exit(1)
    
    # テストリクエスト
    print("🔄 Groq APIへの接続テストを実行中...")
    print(f"   使用モデル: llama3-8b-8192")
    print(f"   APIキー: {api_key[:10]}...{api_key[-4:]}")
    print()
    
    try:
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": "Hello! Can you generate a simple Terraform code to create an S3 bucket?"
                }
            ],
            model="llama3-8b-8192",
        )
        
        print("✅ 接続成功!")
        print("\n" + "="*60)
        print("レスポンス:")
        print("="*60)
        print(chat_completion.choices[0].message.content)
        print("="*60)
        print("\n🎉 Groq APIは正常に動作しています！")
        return 0
        
    except Exception as e:
        print(f"❌ エラー: APIリクエストに失敗しました")
        print(f"   エラー内容: {e}")
        print("\nトラブルシューティング:")
        print("1. APIキーが正しく設定されているか確認:")
        print("   echo $GROQ_API_KEY")
        print("2. インターネット接続を確認")
        print("3. APIキーが正しくコピーされているか確認（gsk_で始まる）")
        print("4. GroqコンソールでAPIキーが有効か確認")
        print("5. 利用可能なモデル名を確認:")
        print("   - llama3-8b-8192（推奨）")
        print("   - llama3-70b-8192")
        print("   - mixtral-8x7b-32768")
        print("   - gemma-7b-it")
        sys.exit(1)

if __name__ == "__main__":
    sys.exit(main())
