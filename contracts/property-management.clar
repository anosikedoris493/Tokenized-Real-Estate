;; Property Management Contract

;; Define data structures
(define-map property-managers
  { property-id: uint }
  { manager: principal }
)

(define-map maintenance-requests
  { request-id: uint }
  { property-id: uint, description: (string-ascii 256), status: (string-ascii 20), cost: uint }
)

(define-data-var last-request-id uint u0)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-property-not-found (err u101))
(define-constant err-request-not-found (err u102))

;; Set property manager
(define-public (set-property-manager (property-id uint) (manager principal))
  (let
    (
      (property (unwrap! (contract-call? .property-tokenization get-property property-id) err-property-not-found))
    )
    (asserts! (is-eq tx-sender (get owner property)) err-not-authorized)
    (ok (map-set property-managers { property-id: property-id } { manager: manager }))
  )
)

;; Create maintenance request
(define-public (create-maintenance-request (property-id uint) (description (string-ascii 256)))
  (let
    (
      (new-request-id (+ (var-get last-request-id) u1))
    )
    (asserts! (is-some (contract-call? .property-tokenization get-property property-id)) err-property-not-found)
    (map-set maintenance-requests
      { request-id: new-request-id }
      { property-id: property-id, description: description, status: "pending", cost: u0 }
    )
    (var-set last-request-id new-request-id)
    (ok new-request-id)
  )
)

;; Update maintenance request status
(define-public (update-request-status (request-id uint) (new-status (string-ascii 20)))
  (let
    (
      (request (unwrap! (map-get? maintenance-requests { request-id: request-id }) err-request-not-found))
      (manager (unwrap! (map-get? property-managers { property-id: (get property-id request) }) err-not-authorized))
    )
    (asserts! (is-eq tx-sender (get manager manager)) err-not-authorized)
    (ok (map-set maintenance-requests
      { request-id: request-id }
      (merge request { status: new-status })))
  )
)

;; Set maintenance request cost
(define-public (set-request-cost (request-id uint) (cost uint))
  (let
    (
      (request (unwrap! (map-get? maintenance-requests { request-id: request-id }) err-request-not-found))
      (manager (unwrap! (map-get? property-managers { property-id: (get property-id request) }) err-not-authorized))
    )
    (asserts! (is-eq tx-sender (get manager manager)) err-not-authorized)
    (ok (map-set maintenance-requests
      { request-id: request-id }
      (merge request { cost: cost })))
  )
)

;; Get maintenance request details
(define-read-only (get-maintenance-request (request-id uint))
  (map-get? maintenance-requests { request-id: request-id })
)

;; Get property manager
(define-read-only (get-property-manager (property-id uint))
  (map-get? property-managers { property-id: property-id })
)

