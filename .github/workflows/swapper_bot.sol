name: Robinhood Auto Swapper Bot

on:
  schedule:
    # این دستور یعنی: «هر ۶ ساعت یک‌بار به صورت خودکار اجرا شو»
    - cron: '0 */6 * * *'
  workflow_dispatch: # قابلیت اینکه دستی از تو گیت‌هاب دکمه Run بزنی

jobs:
  auto-swap:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Run Swapper Bot
        env:
          PK_1: ${{ secrets.KEY_1 }}
          PK_2: ${{ secrets.KEY_2 }}
          PK_3: ${{ secrets.KEY_3 }}
          TOKEN_A: "0x7943e237c7F95DA44E0301572D358911207852Fa" # <-- آدرس توکن اول
          TOKEN_B: "0x7E955252E15c84f5768B83c41a71F9eba181802F" # <-- آدرس توکن دوم
          RPC_URL: "https://rpc.testnet.chain.robinhood.com/"
        run: |
          forge script script/AutoSwapper.s.sol:AutoSwapperScript \
            --rpc-url $RPC_URL \
            --broadcast \
            -vvv
