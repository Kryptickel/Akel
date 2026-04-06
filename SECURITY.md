
---

## **SECURITY.md**

```markdown
# Security Policy

## 🔒 Our Commitment

AKEL Panic Button is a **life-saving application**. Security is not optional—it's essential. We take all security reports seriously and respond quickly.

**Current Security Status:**
- ✅ End-to-End Encryption (AES-256)
- ✅ Zero-knowledge architecture
- ✅ GDPR/CCPA compliant
- 🚧 SOC 2 Type II audit in progress (funded by sponsors)

## 🛡️ Supported Versions

| Version | Supported | Notes |
|---------|-----------|-------|
| Build 58 | ✅ Active support | Current production build (95% complete) |
| < Build 58 | ❌ Not supported | Upgrade to Build 58 |
| Beta versions | ⚠️ Use at own risk | For testing only |

## 🚨 Reporting a Vulnerability

### **⚠️ PLEASE DO NOT REPORT SECURITY VULNERABILITIES PUBLICLY**

**Public disclosure of security issues puts users at risk.**

### How to Report Securely

**Email:** security@akel.app
**Subject:** `[SECURITY] Brief description`

**Include:**
1. **Description** of the vulnerability
2. **Steps to reproduce** (as detailed as possible)
3. **Potential impact** (what an attacker could do)
4. **Suggested fix** (if you have one)
5. **Your contact info** (for follow-up questions)

### What to Expect

- **Acknowledgment:** Within 24 hours
- **Initial Assessment:** Within 72 hours
- **Status Update:** Every 7 days until resolved
- **Fix Timeline:** Critical bugs within 7 days, others within 30 days
- **Public Disclosure:** After fix is deployed (coordinated with you)

### Responsible Disclosure

We follow **responsible disclosure** principles:

1. **You report** the vulnerability privately
2. **We acknowledge** and begin investigation
3. **We develop** a fix
4. **We deploy** the fix to all users
5. **We publicly disclose** (with your permission, crediting you)

## 🎖️ Security Researcher Recognition

**We deeply appreciate security researchers.** If you report a valid security issue:

- ✅ **Public credit** in our security hall of fame (if you want)
- ✅ **Mention in release notes** when fix is deployed
- ✅ **Free Premium account** for 1 year
- ✅ **Swag & stickers** (if you provide shipping address)
- 💰 **Bug bounty** (for critical vulnerabilities, budget permitting)

### Bug Bounty Guidelines

We're a small open-source project (95% complete, seeking sponsors). We can't compete with corporate bug bounties, but we do offer:

| Severity | Reward | Examples |
|----------|--------|----------|
| **Critical** | $500-$1,000 | RCE, auth bypass, data breach |
| **High** | $200-$500 | XSS, SQL injection, privilege escalation |
| **Medium** | $50-$200 | CSRF, encryption weakness |
| **Low** | $0-$50 | Information disclosure, rate limiting |
| **Informational** | Public credit | Best practice violations |

**Note:** Bounties are only paid for vulnerabilities in:
- Current production code (Build 58)
- Not already known/documented
- With clear proof of concept

## 🔐 Security Best Practices We Follow

### **Data Protection**
- ✅ End-to-end encryption for all sensitive data
- ✅ Encrypted at rest in Firebase/AWS
- ✅ Encrypted in transit (TLS 1.3)
- ✅ Zero-knowledge architecture (we can't access user data)
- ✅ Automatic encryption key rotation

### **Authentication & Authorization**
- ✅ Multi-factor authentication (2FA)
- ✅ Biometric authentication (Face ID, fingerprint)
- ✅ Secure session management
- ✅ OAuth 2.0 for third-party integrations
- ✅ Account lockout after failed attempts

### **Infrastructure**
- ✅ Regular security audits
- ✅ Automated vulnerability scanning
- ✅ Dependency updates (Dependabot)
- ✅ Secure CI/CD pipeline
- ✅ Principle of least privilege

### **Code Security**
- ✅ Input validation on all user data
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS prevention (input sanitization)
- ✅ CSRF tokens
- ✅ Regular code reviews

### **Privacy**
- ✅ GDPR compliant (EU)
- ✅ CCPA compliant (California)
- ✅ HIPAA-ready (Enterprise tier)
- ✅ Privacy by design
- ✅ Minimal data collection
- ✅ User data deletion on request

## ⚠️ Known Limitations

We believe in transparency. Current known security considerations:

1. **Emergency Override:** In life-threatening emergencies, users can bypass some security (e.g., panic button works on lock screen). This is intentional for safety.

2. **Location Tracking:** Real-time GPS requires location permissions. We can't protect you without knowing where you are.

3. **Third-Party Services:** We rely on Firebase, AWS, Google Maps. We trust these providers but can't control their security.

4. **Open Source Trade-off:** Our code is open-source for transparency. This helps security researchers find bugs, but also helps attackers.

## 🚫 Out of Scope

The following are **NOT** considered security vulnerabilities:

- ❌ Social engineering attacks on users
- ❌ Physical access to unlocked device
- ❌ Attacks requiring root/jailbreak
- ❌ Denial of service (unless trivial to execute)
- ❌ Issues in outdated versions
- ❌ Theoretical attacks without proof of concept
- ❌ Best practice violations without security impact
- ❌ Issues requiring user to install malware
- ❌ Missing security headers without demonstrable impact

## 📊 Security Audit Status

### Completed ✅
- Internal code review
- Automated SAST scanning
- Dependency vulnerability scanning
- Basic penetration testing

### In Progress 🚧
- **SOC 2 Type II audit** ($8,000 funded by sponsors)
- Third-party penetration testing
- HIPAA compliance documentation (Enterprise)

### Planned 📅
- Annual security audits
- Bug bounty program (when funded)
- Security training for contributors

## 🔗 Security Resources

- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **Flutter Security:** https://flutter.dev/security
- **Firebase Security:** https://firebase.google.com/support/privacy
- **AWS Security:** https://aws.amazon.com/security/

## 📞 Contact

- **Security Issues:** security@akel.app (private)
- **General Security Questions:** GitHub Discussions (public)
- **PGP Key:** Available on request

---

**We appreciate your help in keeping AKEL users safe.** 🛡️

*Last Updated: March 17, 2026*
