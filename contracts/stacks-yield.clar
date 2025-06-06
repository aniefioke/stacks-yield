;; StacksYield - Advanced sBTC Staking Protocol
;; Title: Professional-grade Bitcoin staking on Stacks Layer 2
;; Summary: Secure, time-locked staking with dynamic rewards for Bitcoin holders
;; Description: A production-ready smart contract enabling Bitcoin holders to earn yield
;;              through sBTC staking with configurable reward rates, minimum stake periods,
;;              and comprehensive reward management. Built for institutional and retail
;;              investors seeking Bitcoin-native DeFi opportunities on Stacks.

;; ERROR CODES

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ZERO_STAKE (err u101))
(define-constant ERR_NO_STAKE_FOUND (err u102))
(define-constant ERR_TOO_EARLY_TO_UNSTAKE (err u103))
(define-constant ERR_INVALID_REWARD_RATE (err u104))
(define-constant ERR_NOT_ENOUGH_REWARDS (err u105))

;; DATA STORAGE

;; Individual stake records with amount and timestamp
(define-map stakes
  { staker: principal }
  {
    amount: uint,
    staked-at: uint,
  }
)

;; Track total rewards claimed by each staker
(define-map rewards-claimed
  { staker: principal }
  { amount: uint }
)

;; Protocol configuration variables
(define-data-var reward-rate uint u5) ;; 0.5% in basis points (5/1000)
(define-data-var reward-pool uint u0) ;; Available rewards for distribution
(define-data-var min-stake-period uint u1440) ;; Minimum stake period in blocks (~10 days)
(define-data-var total-staked uint u0) ;; Total sBTC currently staked
(define-data-var contract-owner principal tx-sender)

;; ADMINISTRATIVE FUNCTIONS

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq new-owner (var-get contract-owner))) (ok true))
    (ok (var-set contract-owner new-owner))
  )
)

(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (< new-rate u1000) ERR_INVALID_REWARD_RATE) ;; Cannot exceed 100%
    (ok (var-set reward-rate new-rate))
  )
)

(define-public (set-min-stake-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-period u0) ERR_INVALID_REWARD_RATE)
    (ok (var-set min-stake-period new-period))
  )
)

;; Fund the reward pool with sBTC tokens
(define-public (add-to-reward-pool (amount uint))
  (begin
    (asserts! (> amount u0) ERR_ZERO_STAKE)
    ;; Transfer sBTC tokens to contract
    (try! (contract-call? 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token
      transfer amount tx-sender (as-contract tx-sender) none
    ))
    ;; Update reward pool balance
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)