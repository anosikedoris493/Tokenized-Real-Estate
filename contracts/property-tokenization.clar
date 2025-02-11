;; Property Tokenization Contract

;; Define data structures
(define-map properties
  { property-id: uint }
  { owner: principal, address: (string-ascii 256), value: uint, total-shares: uint }
)

(define-data-var last-property-id uint u0)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-property-not-found (err u101))
(define-constant err-invalid-shares (err u102))

;; Tokenize a new property
(define-public (tokenize-property (address (string-ascii 256)) (value uint) (total-shares uint))
  (let
    (
      (new-property-id (+ (var-get last-property-id) u1))
    )
    (map-set properties
      { property-id: new-property-id }
      { owner: tx-sender, address: address, value: value, total-shares: total-shares }
    )
    (var-set last-property-id new-property-id)
    (ok new-property-id)
  )
)

;; Transfer property ownership
(define-public (transfer-property (property-id uint) (new-owner principal))
  (let
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) err-property-not-found))
    )
    (asserts! (is-eq tx-sender (get owner property)) err-not-authorized)
    (ok (map-set properties
      { property-id: property-id }
      (merge property { owner: new-owner })))
  )
)

;; Get property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Check if a property exists
(define-read-only (property-exists (property-id uint))
  (is-some (map-get? properties { property-id: property-id }))
)

;; Update property value
(define-public (update-property-value (property-id uint) (new-value uint))
  (let
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) err-property-not-found))
    )
    (asserts! (is-eq tx-sender (get owner property)) err-not-authorized)
    (ok (map-set properties
      { property-id: property-id }
      (merge property { value: new-value })))
  )
)

