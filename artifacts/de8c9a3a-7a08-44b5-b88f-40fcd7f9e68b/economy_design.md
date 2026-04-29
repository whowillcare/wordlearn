# Gamification & Economy Design

## Goal
Establish a balanced economy that drives engagement (playing, winning) and monetization (ads, IAP) without frustrating new users.

## Proposed Currency Rules

### 1. User Onboarding & Retention
*   **Initial Balance**: `100 Coins` (Generous start to get them hooked).
*   **Sign-In / Daily Bonus**:
    *   Day 1-6: `+20 Coins`
    *   Day 7 (Streak): `+100 Coins` (Huge incentive to keep streak).

### 2. Core Loop Economy
*   **Cost to Play**: `-10 Coins` per game.
    *   *Rationale*: Creates stakes. 100 coins = 10 risk-free games.
*   **Win Reward**: `+20 Coins` (Net profit: +10).
    *   *Rationale*: Skilled play is sustainable. 50% win rate = break even.
*   **Loss**: `0 Coins` (Net loss: -10).

### 3. Assistance & Spenders (Sinks)
*   **Hints**:
    *   **Tier 1 (Reveal Category)**: `-10 Coins` (Helpful context).
    *   **Tier 2 (Reveal 1 Letter)**: `-25 Coins` (Direct help).
    *   **Tier 3 (Reveal 3 Letters)**: `-50 Coins` (Major help).
    *   **Review/Revive**: `-50 Coins` (+3 guesses).
        *   *Rationale*: Revive is expensive, pushing users towards Rewarded Video or IAP.

### 4. Monetization & Faucets (Sources)
*   **Rewarded Video (Watch Ad)**: `+50 Coins`.
    *   *Rationale*: Pays for a Revive or a major hint instantly. High value perception.
*   **Interstitial**: No reward (Game flow tax).
*   **IAP (Future)**:
    *   Small: 500 Coins ($0.99)
    *   Medium: 1500 Coins ($2.99)
    *   Remove Ads: $4.99 (Includes +1000 Coins one-time?)

## Game Logic Updates Required
1.  **StatisticsRepository**:
    *   Ensure `addPoints` / `deductPoints` are robust.
    *   Add `initialPoints` logic for new users (if clean install).
2.  **GameBloc/GameScreen**:
    *   Update `Cost to Play` to 10.
    *   Update `Win Reward` to 20.
    *   Update `Hint Costs` (10, 25, 50).
    *   Update `Revive Cost` to 50.
3.  **HomeScreen**:
    *   Implement **Daily Bonus** logic (Check last login date vs today).

## Summary Table

| Action | Cost/Reward | Effect |
| :--- | :--- | :--- |
| **New User** | +100 | Start |
| **Play Game** | -10 | Stake |
| **Win Game** | +20 | Reward |
| **Daily Login** | +20 | Retention |
| **Hint (Cat)** | -10 | Assistance |
| **Hint (Letter)**| -25 | Assistance |
| **Revive** | -50 | Survival |
| **Watch Ad** | +50 | Monetization |

> [!NOTE]
> Does this structure look "realistic but attractive" to you? It ensures users can't spam hints forever without winning or watching ads, effectively creating the "Ad Loop".
