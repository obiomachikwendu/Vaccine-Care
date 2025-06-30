# Vaccine Distribution and Immunization Tracking System

## Overview

A comprehensive blockchain-based vaccine distribution and immunization tracking system built on the Stacks blockchain using Clarity smart contracts. This system ensures transparent, tamper-proof recording of vaccine supply chain management and patient vaccination records.

## Features

### Core Functionality

- **Complete Vaccine Lifecycle Tracking**: Monitor vaccines from manufacturing through distribution to administration
- **Cold Chain Compliance**: Real-time temperature tracking with automatic breach detection
- **Multi-Dose Support**: Manage complex vaccination schedules with automatic interval validation
- **Healthcare Provider Management**: Credential verification and facility registration system
- **Inventory Management**: Real-time tracking of vaccine doses across storage facilities
- **Patient Safety**: Comprehensive vaccination history with adverse reaction reporting
- **Anti-Counterfeiting**: Blockchain-based verification prevents fake vaccine distribution

### Technical Features

- Immutable record keeping on blockchain
- Automated expiry checking
- Role-based access control
- Temperature breach threshold monitoring
- Dose interval enforcement
- Batch tracking with unique identifiers

## Architecture

### Data Structures

#### 1. Vaccine Batch Registry
Stores comprehensive information about vaccine batches including:
- Manufacturer details
- Production and expiration dates
- Current inventory levels
- Temperature status
- Storage location
- Cold chain breach count

#### 2. Patient Immunization Database
Maintains patient vaccination records including:
- Complete vaccination history
- Dose scheduling
- Adverse reaction reports
- Medical exemptions
- Healthcare provider information

#### 3. Healthcare Provider Registry
Manages authorized healthcare professionals:
- Professional roles
- Facility affiliations
- License expiration tracking

#### 4. Storage Facility Database
Tracks vaccine storage locations:
- Physical addresses
- Storage capacity
- Current stock levels
- Temperature logs

### System Constants

- **Temperature Range**: -70°C to 8°C
- **Minimum Dose Interval**: 21 days
- **Maximum Doses per Person**: 4
- **Maximum Cold Chain Breaches**: 2 (before batch is marked compromised)

## Installation

### Prerequisites

- [Stacks CLI](https://docs.stacks.co/understand-stacks/command-line-interface)
- Node.js v14+ and npm
- Access to a Stacks node (testnet or mainnet)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/your-org/vaccine-tracking-system
cd vaccine-tracking-system
```

2. Install dependencies:
```bash
npm install
```

3. Configure your Stacks account in `.env`:
```env
STACKS_PRIVATE_KEY=your_private_key
STACKS_NETWORK=testnet
CONTRACT_NAME=vaccine-tracking
```

4. Deploy the contract:
```bash
stx deploy vaccine-tracking.clar
```

## Usage

### Administrator Functions

#### Transfer Administration
```clarity
(contract-call? .vaccine-tracking transfer-administration new-admin-principal)
```

#### Register Healthcare Provider
```clarity
(contract-call? .vaccine-tracking register-healthcare-provider 
    provider-principal
    "doctor"
    "City General Hospital"
    u1000000)  ;; Block height for license expiry
```

#### Register Storage Facility
```clarity
(contract-call? .vaccine-tracking register-storage-facility
    "Central Vaccine Storage"
    "123 Medical District, City, State"
    u10000)  ;; Capacity in doses
```

### Healthcare Provider Functions

#### Register New Vaccine Batch
```clarity
(contract-call? .vaccine-tracking register-vaccine-batch
    "BATCH-2024-001"
    "PharmaCorp"
    "COVID-19 Vaccine"
    u100000  ;; Production date (block height)
    u200000  ;; Expiry date (block height)
    u5000    ;; Number of doses
    -20      ;; Storage temperature
    "Central Vaccine Storage")
```

#### Administer Vaccine
```clarity
(contract-call? .vaccine-tracking administer-vaccine
    "PATIENT-12345"
    "BATCH-2024-001"
    "City General Hospital")
```

#### Log Temperature Breach
```clarity
(contract-call? .vaccine-tracking log-temperature-breach
    "BATCH-2024-001"
    10)  ;; Breach temperature
```

### Query Functions

#### Check Batch Validity
```clarity
(contract-call? .vaccine-tracking verify-batch-validity "BATCH-2024-001")
```

#### Query Patient Record
```clarity
(contract-call? .vaccine-tracking query-patient-record "PATIENT-12345")
```

#### Verify Provider Authorization
```clarity
(contract-call? .vaccine-tracking verify-provider-authorization provider-principal)
```

## API Reference

### Administrative Functions

| Function | Parameters | Description | Access |
|----------|------------|-------------|---------|
| `transfer-administration` | `new-administrator: principal` | Transfer contract ownership | Admin only |
| `register-healthcare-provider` | `provider: principal, role: string, facility: string, license-expiry: uint` | Register new healthcare provider | Admin only |
| `register-storage-facility` | `facility-name: string, address: string, capacity: uint` | Register vaccine storage facility | Admin only |

### Vaccine Management Functions

| Function | Parameters | Description | Access |
|----------|------------|-------------|---------|
| `register-vaccine-batch` | Multiple (see usage) | Register new vaccine batch | Authorized providers |
| `update-batch-status` | `batch-id: string, new-status: string` | Update batch operational status | Authorized providers |
| `log-temperature-breach` | `batch-id: string, breach-temp: int` | Record temperature violation | Authorized providers |

### Patient Care Functions

| Function | Parameters | Description | Access |
|----------|------------|-------------|---------|
| `administer-vaccine` | `patient-id: string, batch-id: string, clinic-location: string` | Record vaccine administration | Authorized providers |

### Read-Only Functions

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `get-contract-administrator` | None | `principal` | Get current administrator |
| `verify-provider-authorization` | `provider: principal` | `bool` | Check provider authorization |
| `query-vaccine-batch` | `batch-id: string` | `batch data or none` | Get batch information |
| `query-patient-record` | `patient-id: string` | `patient data or none` | Get patient vaccination history |
| `verify-batch-validity` | `batch-id: string` | `bool` | Check if batch is valid for use |

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR-UNAUTHORIZED-ACCESS` | Caller lacks required permissions |
| u101 | `ERR-INVALID-BATCH-DATA` | Batch data validation failed |
| u102 | `ERR-BATCH-ALREADY-EXISTS` | Batch ID already registered |
| u103 | `ERR-BATCH-NOT-FOUND` | Batch ID not found in registry |
| u104 | `ERR-INSUFFICIENT-DOSES` | Not enough doses in batch |
| u105 | `ERR-INVALID-PATIENT-DATA` | Patient data validation failed |
| u106 | `ERR-PATIENT-ALREADY-DOSED` | Patient already received this dose |
| u107 | `ERR-TEMPERATURE-VIOLATION` | Temperature outside acceptable range |
| u108 | `ERR-BATCH-EXPIRED` | Vaccine batch has expired |
| u109 | `ERR-INVALID-FACILITY` | Facility validation failed |
| u110 | `ERR-MAX-DOSES-EXCEEDED` | Patient exceeded maximum doses |
| u111 | `ERR-DOSE-INTERVAL-VIOLATION` | Minimum interval between doses not met |
| u112 | `ERR-ADMIN-ONLY` | Function restricted to administrator |
| u113 | `ERR-INVALID-INPUT-DATA` | Input data validation failed |
| u114 | `ERR-INVALID-EXPIRATION` | Invalid expiration date |
| u115 | `ERR-INVALID-CAPACITY` | Invalid storage capacity |

## Security Considerations

### Access Control
- Contract administrator has privileged access for system configuration
- Healthcare providers must be registered before accessing vaccine management functions
- All modifications require proper authorization

### Data Integrity
- Blockchain ensures immutable record keeping
- Temperature breaches are permanently recorded
- Patient vaccination history cannot be altered or deleted

### Best Practices
1. Regularly update healthcare provider credentials
2. Monitor cold chain breaches closely
3. Implement off-chain backup systems for critical data
4. Use secure key management for administrator accounts
5. Conduct regular audits of vaccine inventory

### Potential Vulnerabilities
- Single administrator control point (consider multi-sig in production)
- No mechanism to remove compromised providers (implement in production)
- Limited temperature log history (100 entries max)