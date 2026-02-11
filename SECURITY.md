# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |

## Reporting a Vulnerability

We take the security of Scroll Down iOS seriously. If you discover a security vulnerability, please report it responsibly:

### How to Report

1. **Do NOT** open a public issue
2. Email security concerns to: [Add your security email here]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- Acknowledgment within 48 hours
- Regular updates on progress
- Credit in release notes (if desired)

## Security Measures

### Code Quality
- SwiftLint enforcement for code quality
- CodeQL security scanning on all PRs
- Automated dependency updates via Dependabot

### API Security
- API keys stored in environment configuration
- HTTPS-only communication with backend
- Proper error handling to avoid information leakage

### Data Protection
- User preferences stored in UserDefaults (non-sensitive only)
- No collection of personal information
- No tracking or analytics

### Known Limitations

1. **API Key Storage**: Currently stored in Info.plist. Consider using Keychain for production.
2. **Certificate Pinning**: Not implemented. URLSession uses system trust store.
3. **Rate Limiting**: Client-side only. Server should enforce rate limits.

## Best Practices for Contributors

1. Never commit secrets, API keys, or credentials
2. Use guard statements instead of force unwraps
3. Validate all network responses
4. Handle errors gracefully with user feedback
5. Use AppDate.now() instead of Date() for testability
6. Avoid force casts and force unwraps
7. Review SwiftLint warnings before submitting PRs

## Security Checklist for PRs

- [ ] No hardcoded secrets or API keys
- [ ] No force unwraps (!) in production code paths
- [ ] Proper error handling for all network calls
- [ ] Input validation for user-provided data
- [ ] SwiftLint passes without errors
- [ ] CodeQL analysis shows no new vulnerabilities
- [ ] Tests cover security-relevant code paths

## Regular Security Reviews

- Quarterly dependency audit
- Annual penetration testing (production app)
- Regular code review of security-sensitive changes

## Dependencies

We use Dependabot to keep dependencies up to date. All dependency updates are reviewed before merging.

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find similar problems
3. Prepare fixes for all supported versions
4. Release patches as soon as possible

## Contact

For security concerns, contact: [Add contact information]

---

Last updated: 2026-02-11
