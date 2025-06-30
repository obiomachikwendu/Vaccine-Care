;; Vaccine Distribution and Immunization Tracking System Smart Contract
;; 
;; Description:
;; A comprehensive blockchain-based vaccine distribution and immunization tracking system
;; that ensures transparent, tamper-proof recording of vaccine supply chain management
;; and patient vaccination records. This smart contract enables healthcare providers to:
;; - Track vaccine batches from manufacturing through distribution
;; - Monitor cold chain compliance with temperature tracking
;; - Record patient vaccinations with multi-dose support
;; - Manage healthcare provider credentials and facility registrations
;; - Ensure vaccine authenticity and prevent counterfeit medications
;;
;; Key Features:
;; - Complete vaccine lifecycle tracking from manufacture to administration
;; - Temperature breach monitoring for cold chain integrity
;; - Multi-dose vaccination schedule enforcement
;; - Healthcare provider authorization and credential management
;; - Storage facility inventory and capacity tracking
;; - Patient vaccination history with side effect reporting
;; - Automated dose interval validation and expiry checking
;;

;; Contract Ownership
(define-data-var contract-administrator principal tx-sender)

;; Error Constants

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-BATCH-DATA (err u101))
(define-constant ERR-BATCH-ALREADY-EXISTS (err u102))
(define-constant ERR-BATCH-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-DOSES (err u104))
(define-constant ERR-INVALID-PATIENT-DATA (err u105))
(define-constant ERR-PATIENT-ALREADY-DOSED (err u106))
(define-constant ERR-TEMPERATURE-VIOLATION (err u107))
(define-constant ERR-BATCH-EXPIRED (err u108))
(define-constant ERR-INVALID-FACILITY (err u109))
(define-constant ERR-MAX-DOSES-EXCEEDED (err u110))
(define-constant ERR-DOSE-INTERVAL-VIOLATION (err u111))
(define-constant ERR-ADMIN-ONLY (err u112))
(define-constant ERR-INVALID-INPUT-DATA (err u113))
(define-constant ERR-INVALID-EXPIRATION (err u114))
(define-constant ERR-INVALID-CAPACITY (err u115))
(define-constant ERR-INVALID-PRINCIPAL (err u116))
(define-constant ERR-SELF-TRANSFER (err u117))


;; System Constants

(define-constant min-cold-storage-temp (- 70))
(define-constant max-cold-storage-temp 8)
(define-constant min-dose-interval-days u21)
(define-constant max-doses-per-person u4)
(define-constant min-text-length u1)
(define-constant current-block-height block-height)

;; Data Storage Structures

;; Vaccine Batch Registry
(define-map vaccine-batch-registry
    { batch-identifier: (string-ascii 32) }
    {
        manufacturer-name: (string-ascii 50),
        vaccine-product-name: (string-ascii 50),
        production-date: uint,
        expiration-date: uint,
        remaining-doses: uint,
        current-storage-temp: int,
        operational-status: (string-ascii 20),
        cold-chain-breaches: uint,
        storage-location: (string-ascii 100),
        batch-notes: (string-ascii 500)
    }
)

;; Patient Immunization Database
(define-map patient-immunization-database
    { patient-id: (string-ascii 32) }
    {
        vaccination-events: (list 10 {
            batch-id: (string-ascii 32),
            administration-timestamp: uint,
            vaccine-product: (string-ascii 50),
            dose-number: uint,
            administering-provider: principal,
            clinic-location: (string-ascii 100),
            next-dose-due: (optional uint)
        }),
        total-doses-received: uint,
        adverse-reactions: (list 5 (string-ascii 200)),
        medical-exemption: (optional (string-ascii 200))
    }
)

;; Healthcare Provider Registry
(define-map healthcare-provider-registry
    principal
    {
        professional-role: (string-ascii 20),
        affiliated-facility: (string-ascii 100),
        license-expiration: uint
    }
)

;; Storage Facility Database
(define-map storage-facility-database
    (string-ascii 100)
    {
        physical-address: (string-ascii 200),
        total-capacity: uint,
        current-stock-level: uint,
        temperature-log: (list 100 {
            timestamp: uint,
            temperature-reading: int
        })
    }
)

;; Internal Validation Functions

(define-private (is-contract-administrator)
    (is-eq tx-sender (var-get contract-administrator))
)

(define-private (validate-short-text (text (string-ascii 32)))
    (> (len text) min-text-length)
)

(define-private (validate-medium-text (text (string-ascii 50)))
    (> (len text) min-text-length)
)

(define-private (validate-standard-text (text (string-ascii 100)))
    (> (len text) min-text-length)
)

(define-private (validate-long-text (text (string-ascii 200)))
    (> (len text) min-text-length)
)

(define-private (validate-role-text (text (string-ascii 20)))
    (> (len text) min-text-length)
)

(define-private (validate-future-timestamp (timestamp uint))
    (> timestamp current-block-height)
)

(define-private (validate-positive-quantity (quantity uint))
    (> quantity u0)
)

;; Add validation for principal
(define-private (validate-principal (principal-to-check principal))
    (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78))
)

;; Read-Only Query Functions

(define-read-only (get-contract-administrator)
    (ok (var-get contract-administrator))
)

(define-read-only (verify-provider-authorization (provider principal))
    (match (map-get? healthcare-provider-registry provider)
        provider-data (>= (get license-expiration provider-data) current-block-height)
        false
    )
)

(define-read-only (query-vaccine-batch (batch-id (string-ascii 32)))
    (map-get? vaccine-batch-registry {batch-identifier: batch-id})
)

(define-read-only (query-patient-record (patient-id (string-ascii 32)))
    (map-get? patient-immunization-database {patient-id: patient-id})
)

(define-read-only (query-storage-facility (facility-name (string-ascii 100)))
    (map-get? storage-facility-database facility-name)
)

(define-read-only (verify-batch-validity (batch-id (string-ascii 32)))
    (match (map-get? vaccine-batch-registry {batch-identifier: batch-id})
        batch-data (and
            (is-eq (get operational-status batch-data) "active")
            (> (get remaining-doses batch-data) u0)
            (<= current-block-height (get expiration-date batch-data))
            (<= (get cold-chain-breaches batch-data) u2))
        false
    )
)

;; Administrative Functions

(define-public (transfer-administration (new-administrator principal))
    (begin
        (asserts! (is-contract-administrator) ERR-ADMIN-ONLY)
        ;; Validate the new administrator principal
        (asserts! (validate-principal new-administrator) ERR-INVALID-PRINCIPAL)
        ;; Ensure not transferring to self
        (asserts! (not (is-eq tx-sender new-administrator)) ERR-SELF-TRANSFER)
        (ok (var-set contract-administrator new-administrator))
    )
)

(define-public (register-healthcare-provider
    (provider principal)
    (role (string-ascii 20))
    (facility (string-ascii 100))
    (license-expiry uint))
    (begin
        (asserts! (is-contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        ;; Validate the provider principal
        (asserts! (validate-principal provider) ERR-INVALID-PRINCIPAL)
        (asserts! (validate-role-text role) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-standard-text facility) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-future-timestamp license-expiry) ERR-INVALID-EXPIRATION)
        (ok (map-set healthcare-provider-registry
            provider
            {
                professional-role: role,
                affiliated-facility: facility,
                license-expiration: license-expiry
            }))
    )
)

(define-public (register-storage-facility
    (facility-name (string-ascii 100))
    (address (string-ascii 200))
    (capacity uint))
    (begin
        (asserts! (is-contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-standard-text facility-name) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-long-text address) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-positive-quantity capacity) ERR-INVALID-CAPACITY)
        (ok (map-set storage-facility-database
            facility-name
            {
                physical-address: address,
                total-capacity: capacity,
                current-stock-level: u0,
                temperature-log: (list)
            }))
    )
)

;; Vaccine Management Functions

(define-public (register-vaccine-batch
    (batch-id (string-ascii 32))
    (manufacturer (string-ascii 50))
    (product-name (string-ascii 50))
    (production-date uint)
    (expiry-date uint)
    (dose-count uint)
    (storage-temp int)
    (facility (string-ascii 100)))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-text batch-id) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-medium-text manufacturer) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-medium-text product-name) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-standard-text facility) ERR-INVALID-INPUT-DATA)
        (asserts! (is-none (map-get? vaccine-batch-registry {batch-identifier: batch-id})) ERR-BATCH-ALREADY-EXISTS)
        (asserts! (validate-positive-quantity dose-count) ERR-INVALID-BATCH-DATA)
        (asserts! (validate-future-timestamp expiry-date) ERR-INVALID-EXPIRATION)
        (asserts! (> expiry-date production-date) ERR-INVALID-BATCH-DATA)
        (asserts! (and (>= storage-temp min-cold-storage-temp)
                      (<= storage-temp max-cold-storage-temp))
                 ERR-TEMPERATURE-VIOLATION)
        
        (ok (map-set vaccine-batch-registry
            {batch-identifier: batch-id}
            {
                manufacturer-name: manufacturer,
                vaccine-product-name: product-name,
                production-date: production-date,
                expiration-date: expiry-date,
                remaining-doses: dose-count,
                current-storage-temp: storage-temp,
                operational-status: "active",
                cold-chain-breaches: u0,
                storage-location: facility,
                batch-notes: ""
            }))
    )
)

(define-public (update-batch-status
    (batch-id (string-ascii 32))
    (new-status (string-ascii 20)))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-text batch-id) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-role-text new-status) ERR-INVALID-INPUT-DATA)
        (match (map-get? vaccine-batch-registry {batch-identifier: batch-id})
            batch-data (ok (map-set vaccine-batch-registry
                {batch-identifier: batch-id}
                (merge batch-data {operational-status: new-status})))
            ERR-BATCH-NOT-FOUND
        )
    )
)

(define-public (log-temperature-breach
    (batch-id (string-ascii 32))
    (breach-temp int))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-text batch-id) ERR-INVALID-INPUT-DATA)
        (match (map-get? vaccine-batch-registry {batch-identifier: batch-id})
            batch-data (ok (map-set vaccine-batch-registry
                {batch-identifier: batch-id}
                (merge batch-data {
                    cold-chain-breaches: (+ (get cold-chain-breaches batch-data) u1),
                    operational-status: (if (> (get cold-chain-breaches batch-data) u2)
                                          "compromised"
                                          (get operational-status batch-data))
                })))
            ERR-BATCH-NOT-FOUND
        )
    )
)

;; Patient Vaccination Functions

(define-public (administer-vaccine
    (patient-id (string-ascii 32))
    (batch-id (string-ascii 32))
    (clinic-location (string-ascii 100)))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-text patient-id) ERR-INVALID-PATIENT-DATA)
        (asserts! (validate-short-text batch-id) ERR-INVALID-INPUT-DATA)
        (asserts! (validate-standard-text clinic-location) ERR-INVALID-FACILITY)
        
        (match (map-get? vaccine-batch-registry {batch-identifier: batch-id})
            batch-data (begin
                (asserts! (> (get remaining-doses batch-data) u0) ERR-INSUFFICIENT-DOSES)
                (asserts! (is-eq (get operational-status batch-data) "active") ERR-INVALID-BATCH-DATA)
                (asserts! (<= current-block-height (get expiration-date batch-data)) ERR-BATCH-EXPIRED)
                
                ;; Update batch inventory
                (map-set vaccine-batch-registry
                    {batch-identifier: batch-id}
                    (merge batch-data {remaining-doses: (- (get remaining-doses batch-data) u1)}))
                
                ;; Process patient vaccination
                (match (map-get? patient-immunization-database {patient-id: patient-id})
                    patient-record (begin
                        (asserts! (< (get total-doses-received patient-record) max-doses-per-person)
                                ERR-MAX-DOSES-EXCEEDED)
                        
                        (let ((new-dose-number (+ (get total-doses-received patient-record) u1)))
                            ;; Validate dose interval for subsequent doses
                            (if (> new-dose-number u1)
                                (asserts! (>= (- current-block-height
                                    (get administration-timestamp (unwrap-panic (element-at
                                        (get vaccination-events patient-record)
                                        (- new-dose-number u2)))))
                                    min-dose-interval-days)
                                    ERR-DOSE-INTERVAL-VIOLATION)
                                true
                            )
                            
                            ;; Record vaccination
                            (ok (map-set patient-immunization-database
                                {patient-id: patient-id}
                                {
                                    vaccination-events: (unwrap-panic (as-max-len?
                                        (append (get vaccination-events patient-record)
                                            {
                                                batch-id: batch-id,
                                                administration-timestamp: current-block-height,
                                                vaccine-product: (get vaccine-product-name batch-data),
                                                dose-number: new-dose-number,
                                                administering-provider: tx-sender,
                                                clinic-location: clinic-location,
                                                next-dose-due: (some (+ current-block-height min-dose-interval-days))
                                            }
                                        ) u10)),
                                    total-doses-received: new-dose-number,
                                    adverse-reactions: (get adverse-reactions patient-record),
                                    medical-exemption: (get medical-exemption patient-record)
                                }))))
                    ;; First vaccination for patient
                    (ok (map-set patient-immunization-database
                        {patient-id: patient-id}
                        {
                            vaccination-events: (list
                                {
                                    batch-id: batch-id,
                                    administration-timestamp: current-block-height,
                                    vaccine-product: (get vaccine-product-name batch-data),
                                    dose-number: u1,
                                    administering-provider: tx-sender,
                                    clinic-location: clinic-location,
                                    next-dose-due: (some (+ current-block-height min-dose-interval-days))
                                }),
                            total-doses-received: u1,
                            adverse-reactions: (list),
                            medical-exemption: none
                        })))
            )
            ERR-BATCH-NOT-FOUND
        )
    )
)