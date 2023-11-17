// Technical owner address that will be used for protected collections
export const technicalOwner = '0xD05B13E2C5E0e1071442F9F7C99beE136ecced43'
// Account who can update MetaEvidences
export const metaEvidenceLoader = '0xD05B13E2C5E0e1071442F9F7C99beE136ecced43'
// Fee for protecting (Wei)
export const basicFeeWei = 10000000000000000n
export const ultraFeeWei = 20000000000000000n
// Arbitrators config
export const arbitrators = {
    "sepolia": {
        "name": "Kleros",
        "address": "0x1780601e6465f32233643f3af54abc3d8df161be",
        "extraData": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003"
    }
}
// List of MetaEvidences to be registered
export const metaEvidences = [
    {
        "id": 3,
        "name": "OwnershipAdjustment",
        "url": "/ipfs/QmQenFQfQgXQHV9Whf3FG1JJ6tJu5fyL7mQyDPnjtveenz/metaEvidence.json"
    }, {
        "id": 4,
        "name": "AskOwnershipRestoreArbitrate-Mistake",
        "url": "/ipfs/QmYKeA1xREyEGxjcdHo3tdii6hXaYJtP9LKdvff114oKay/metaEvidence.json"
    }, {
        "id": 5,
        "name": "AskOwnershipRestoreArbitrate-Phishing",
        "url": "/ipfs/QmXFXrprk5b1eN3iVvCQ57TUcr1DUWVBzUooS8jVFJomi5/metaEvidence.json"
    }, {
        "id": 6,
        "name": "AskOwnershipRestoreArbitrate-ProtocolBreach",
        "url": "/ipfs/QmTF9mXDaabUZHiNfDiNSdA45TQCFxh9A45cPhTwY1e4fN/metaEvidence.json"
    }
]