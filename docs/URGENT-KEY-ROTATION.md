# 🚨 URGENT: Rotating Compromised AWS Keys

## ⚠️ CRITICAL SITUATION

Your AWS credentials have been exposed and are considered **compromised**. You **MUST IMMEDIATELY** revoke and replace them.

## 📋 Immediate Actions (Execute NOW!)

### Step 1: Log into AWS Console

1. Navigate to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with your credentials

### Step 2: Revoke Compromised Keys

1. Go to **IAM** (Identity and Access Management)
2. In the left menu, select **Users**
3. Find and open the user who owns the keys
4. Navigate to the **Security credentials** tab
5. In the **Access keys** section, locate:
   - Access Key ID: `AKIATATKADR6UBWJ3IMX`
6. Click **Actions** → **Deactivate**
7. After deactivation, click **Delete**
8. Confirm deletion

### Step 3: Check Access Logs

1. Navigate to **CloudTrail**
2. Review **Event history** for the past few hours
3. Filter by User name
4. Check for suspicious activity:
   - Unknown IP addresses
   - Unusual regions
   - Unexpected actions (resource creation, deletion, modifications)

### Step 4: Assess Potential Damage

If suspicious activity is found:

1. Immediately contact AWS Support
2. Follow their incident remediation instructions
3. Check billing for unexpected charges
4. Consider enabling AWS GuardDuty for monitoring

## ✅ Transition to Secure Method: OIDC

**DO NOT create new long-lived keys!** Instead, use OIDC (OpenID Connect) - it's more secure.

### OIDC Advantages:

- ✅ Temporary tokens (automatically expire)
- ✅ Automatic rotation
- ✅ No storage of long-lived keys
- ✅ Repository and branch-level restrictions
- ✅ Complies with security best practices

### OIDC Setup Instructions:

See detailed guide in: [`docs/aws-bedrock-oidc-setup.md`](./aws-bedrock-oidc-setup.md)

## 🔒 If IAM Access Keys Are Still Needed

If OIDC is not suitable and you need Access Keys:

### Creating New Keys (SECURELY)

1. **IAM** → **Users** → your user
2. **Security credentials** → **Create access key**
3. Use case: select "Application running outside AWS"
4. **IMMEDIATELY** save keys to a secure location
5. **NEVER** publish them:
   - ❌ Not in code
   - ❌ Not in chat
   - ❌ Not in documentation
   - ❌ Not in commit messages
   - ✅ ONLY in GitHub Secrets!

### Adding Keys to GitHub Secrets

1. Open your repository on GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

**First secret:**
- Name: `AWS_ACCESS_KEY_ID`
- Value: your new Access Key ID
- **Add secret**

**Second secret:**
- Name: `AWS_SECRET_ACCESS_KEY`
- Value: your new Secret Access Key
- **Add secret**

**Third secret (optional):**
- Name: `AWS_REGION`
- Value: `eu-north-1`
- **Add secret**

## 📊 Security Monitoring

### Enable Additional Security Measures:

1. **AWS CloudTrail** - logging all actions
2. **AWS GuardDuty** - threat detection
3. **AWS Config** - configuration change tracking
4. **Cost Anomaly Detection** - unusual spending monitoring

### Configure Alerts:

1. CloudWatch Alarms for:
   - Unusual API usage
   - Access attempts from unknown IPs
   - Creation of expensive resources

2. Billing Alerts for:
   - Budget overruns
   - Unusual spending growth

## 🛡️ Security Best Practices

### Never Do:

- ❌ Don't publish credentials in code
- ❌ Don't send credentials in chats/email
- ❌ Don't store credentials in plain text files
- ❌ Don't use the same keys for multiple projects
- ❌ Don't grant keys more permissions than necessary

### Always Do:

- ✅ Use OIDC when possible
- ✅ Store credentials in secret managers
- ✅ Apply Principle of Least Privilege
- ✅ Regularly rotate keys (every 90 days)
- ✅ Enable MFA for AWS Console
- ✅ Monitor access logs
- ✅ Use AWS Organizations for centralized management

## 📞 Support Contacts

### If Suspicious Activity Is Detected:

**AWS Support:**
- Email: aws-security@amazon.com
- Phone: +1 (877) 312-4782
- Console: AWS Support Center

**GitHub Security:**
- Email: security@github.com
- Docs: https://docs.github.com/en/code-security

## 📚 Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [OWASP Top 10 for Cloud](https://owasp.org/www-project-cloud-security/)

## ✅ Security Checklist

After the incident, ensure that:

- [ ] Old keys are deleted from AWS
- [ ] CloudTrail logs checked for suspicious activity
- [ ] Security alerts enabled
- [ ] New authentication method configured (OIDC recommended)
- [ ] Incident documented
- [ ] Team informed about security policies
- [ ] Cost monitoring enabled

---

**Important:** Security is a process, not a one-time task. Regularly review and update your security measures!
