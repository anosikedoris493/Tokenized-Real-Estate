;; Fractional Ownership Contract

;; Define the fungible token
(define-fungible-token property-share)

;; Define data structures
(define-map share-ownership
  { property-id: uint, owner: principal }
  { shares: uint }
)

(define-map property-shares
  { property-id: uint }
  { total-shares: uint, available-shares: uint }
)

;; Error codes
(define-constant err-insufficient-shares (err u100))
(define-constant err-shares-not-available (err u101))
(define-constant err-property-not-found (err u102))

;; Initialize shares for a property
(define-public (initialize-shares (property-id uint) (total-shares uint))
  (let
    (
      (existing-shares (map-get? property-shares { property-id: property-id }))
    )
    (asserts! (is-none existing-shares) err-property-not-found)
    (try! (ft-mint? property-share total-shares tx-sender))
    (map-set property-shares
      { property-id: property-id }
      { total-shares: total-shares, available-shares: total-shares }
    )
    (ok true)
  )
)

;; Buy shares
(define-public (buy-shares (property-id uint) (amount uint))
  (let
    (
      (shares (unwrap! (map-get? property-shares { property-id: property-id }) err-property-not-found))
      (available (get available-shares shares))
    )
    (asserts! (<= amount available) err-shares-not-available)
    (try! (ft-transfer? property-share amount tx-sender (as-contract tx-sender)))
    (map-set property-shares
      { property-id: property-id }
      (merge shares { available-shares: (- available amount) })
    )
    (map-set share-ownership
      { property-id: property-id, owner: tx-sender }
      { shares: (+ (default-to u0 (get shares (map-get? share-ownership { property-id: property-id, owner: tx-sender }))) amount) }
    )
    (ok true)
  )
)

;; Transfer shares
(define-public (transfer-shares (property-id uint) (amount uint) (recipient principal))
  (let
    (
      (sender-shares (unwrap! (map-get? share-ownership { property-id: property-id, owner: tx-sender }) err-insufficient-shares))
    )
    (asserts! (>= (get shares sender-shares) amount) err-insufficient-shares)
    (try! (ft-transfer? property-share amount tx-sender recipient))
    (map-set share-ownership
      { property-id: property-id, owner: tx-sender }
      { shares: (- (get shares sender-shares) amount) }
    )
    (map-set share-ownership
      { property-id: property-id, owner: recipient }
      { shares: (+ (default-to u0 (get shares (map-get? share-ownership { property-id: property-id, owner: recipient }))) amount) }
    )
    (ok true)
  )
)

;; Get shares owned by an address for a property
(define-read-only (get-shares (property-id uint) (owner principal))
  (default-to u0 (get shares (map-get? share-ownership { property-id: property-id, owner: owner })))
)

;; Get total and available shares for a property
(define-read-only (get-property-shares (property-id uint))
  (map-get? property-shares { property-id: property-id })
)

