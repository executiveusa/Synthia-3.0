# Coolify Migration Checklist for Synthia 3.0

## Overview

This checklist guides you through migrating Synthia 3.0 from Railway to Coolify when:
- Railway free tier limits are reached
- Cost optimization is needed
- More control over infrastructure is required
- Private networking (VPN) is desired

## Pre-Migration Checklist

### Infrastructure Assessment

- [ ] **Identify Current Railway Setup**
  - [ ] Note all environment variables
  - [ ] Document current resource usage
  - [ ] List all connected services (PostgreSQL, etc.)
  - [ ] Export current DATABASE_URL

- [ ] **Prepare Coolify Environment**
  - [ ] VPS provisioned (minimum 2GB RAM, 2 CPU cores)
  - [ ] Coolify installed and accessible
  - [ ] Domain name configured (optional but recommended)
  - [ ] SSH access configured

- [ ] **Backup Current Data**
  - [ ] Export PostgreSQL database from Railway
  - [ ] Backup environment variables
  - [ ] Save any uploaded files or workspace data
  - [ ] Document API integrations

## Migration Steps

### Phase 1: Database Migration

- [ ] **Export Railway Database**
  ```bash
  # Get Railway database URL
  railway variables get DATABASE_URL
  
  # Export database dump
  pg_dump $RAILWAY_DATABASE_URL > synthia_backup.sql
  
  # Or use Railway CLI
  railway run pg_dump > synthia_backup.sql
  ```

- [ ] **Set Up PostgreSQL on Coolify**
  - [ ] Create PostgreSQL service in Coolify
  - [ ] Note the new DATABASE_URL
  - [ ] Configure persistent volume for data

- [ ] **Import Data to Coolify**
  ```bash
  # Upload dump file to server
  scp synthia_backup.sql user@your-coolify-server:/tmp/
  
  # Import to new database
  docker exec -i <postgres-container> psql -U postgres -d synthia < /tmp/synthia_backup.sql
  
  # Verify import
  docker exec -it <postgres-container> psql -U postgres -d synthia -c "\dt"
  ```

- [ ] **Test Database Connection**
  - [ ] Connect using new DATABASE_URL
  - [ ] Verify all tables exist
  - [ ] Check row counts match

### Phase 2: Application Deployment

- [ ] **Configure Coolify Project**
  - [ ] Create new application in Coolify
  - [ ] Connect GitHub repository
  - [ ] Select correct branch (main)
  - [ ] Choose Dockerfile.backend as build target

- [ ] **Transfer Environment Variables**
  - [ ] Copy all variables from Railway to Coolify
  - [ ] Update DATABASE_URL to new PostgreSQL instance
  - [ ] Verify all required secrets are set
  - [ ] Test with staging deployment first

- [ ] **Deploy Application**
  ```bash
  # Via Coolify dashboard: click "Deploy"
  # Or via CLI:
  coolify deploy synthia-backend
  ```

- [ ] **Verify Deployment**
  - [ ] Check health endpoint: `https://your-domain.com/healthz`
  - [ ] Test API endpoints
  - [ ] Monitor logs for errors
  - [ ] Verify database connectivity

### Phase 3: DNS and Domain Configuration

- [ ] **Update DNS Records**
  - [ ] Point domain to new Coolify server IP
  - [ ] Update A record: `synthia.example.com → new.ip.address`
  - [ ] Wait for DNS propagation (up to 48 hours)
  - [ ] Keep Railway running during transition

- [ ] **Configure SSL/TLS**
  - [ ] Enable automatic HTTPS in Coolify
  - [ ] Verify certificate provisioning
  - [ ] Test HTTPS access

- [ ] **Update External Integrations**
  - [ ] Update OAuth redirect URLs
  - [ ] Update webhook endpoints
  - [ ] Update API documentation
  - [ ] Notify users of new URLs (if applicable)

### Phase 4: Testing and Validation

- [ ] **Functional Testing**
  - [ ] Test authentication flows
  - [ ] Test agent orchestration
  - [ ] Test voice interview features
  - [ ] Test file upload/download
  - [ ] Test AI provider integrations

- [ ] **Performance Testing**
  - [ ] Load test API endpoints
  - [ ] Check response times
  - [ ] Monitor resource usage
  - [ ] Verify auto-scaling (if configured)

- [ ] **Security Validation**
  - [ ] Verify HTTPS is enforced
  - [ ] Test firewall rules
  - [ ] Validate VPN tunnel (if using Hostinger)
  - [ ] Review security headers

### Phase 5: Monitoring Setup

- [ ] **Configure Monitoring**
  - [ ] Set up health check alerts
  - [ ] Configure log aggregation
  - [ ] Enable resource monitoring
  - [ ] Set up uptime monitoring (e.g., UptimeRobot)

- [ ] **Enable Backups**
  - [ ] Configure automated database backups
  - [ ] Set backup retention policy (7 days recommended)
  - [ ] Test backup restoration
  - [ ] Document backup procedures

- [ ] **Set Up Alerting**
  - [ ] Email alerts for downtime
  - [ ] Slack/Discord webhooks (optional)
  - [ ] Resource usage alerts
  - [ ] Error rate monitoring

### Phase 6: Railway Cleanup

- [ ] **Verify Migration Success**
  - [ ] All features working on Coolify
  - [ ] No errors in logs for 24 hours
  - [ ] Users can access new deployment
  - [ ] Database integrity confirmed

- [ ] **Decommission Railway**
  - [ ] Remove Railway deployment (keep database backup)
  - [ ] Cancel Railway subscription (if paid)
  - [ ] Update documentation with new URLs
  - [ ] Archive Railway configuration for reference

- [ ] **Final Documentation**
  - [ ] Update README.md with Coolify instructions
  - [ ] Document new deployment process
  - [ ] Update CONTRIBUTING.md
  - [ ] Create runbook for operations

## Rollback Plan

In case migration fails:

### Immediate Rollback Steps

- [ ] **Revert DNS**
  ```bash
  # Point domain back to Railway
  # Update A record to Railway IP
  ```

- [ ] **Restart Railway Service**
  ```bash
  railway up
  ```

- [ ] **Notify Users**
  - [ ] Post status update
  - [ ] Communicate timeline for retry

### Investigation Steps

- [ ] Review Coolify logs
- [ ] Check database connectivity
- [ ] Verify environment variables
- [ ] Test individual components
- [ ] Document failure reasons

## Cost Comparison

### Before (Railway)

| Service | Cost |
|---------|------|
| Railway Free Tier | $0/month (limited) |
| Railway Starter | $5/month |
| PostgreSQL Plugin | $5/month |
| **Total** | **$0-10/month** |

### After (Coolify on Hostinger)

| Service | Cost |
|---------|------|
| Hostinger VPS-1 (2GB RAM) | $5-7/month |
| PostgreSQL (included) | $0 |
| Ollama (included) | $0 |
| **Total** | **$5-7/month** |

### Savings

- **Cost Reduction:** ~30-50%
- **More Resources:** 2x RAM, dedicated CPU
- **No Usage Limits:** Unlimited deployments
- **Private Network:** VPN included

## Hostinger VPN Configuration (Optional)

If using Hostinger VPN for private networking:

### Step 1: VPN Setup

- [ ] **Install WireGuard**
  ```bash
  apt-get update
  apt-get install wireguard-tools
  ```

- [ ] **Generate Keys**
  ```bash
  wg genkey | tee privatekey | wg pubkey > publickey
  ```

- [ ] **Configure Interface**
  ```bash
  # Create /etc/wireguard/wg0.conf
  [Interface]
  PrivateKey = <private-key>
  Address = 10.0.0.1/24
  ListenPort = 51820
  ```

- [ ] **Start VPN**
  ```bash
  wg-quick up wg0
  systemctl enable wg-quick@wg0
  ```

### Step 2: Connect Services

- [ ] Update DATABASE_URL to use VPN IP
- [ ] Configure internal service discovery
- [ ] Test connectivity through VPN
- [ ] Document network topology

## Troubleshooting Guide

### Common Issues

**Issue: Database Connection Timeout**
- **Solution:** Check firewall rules, verify DATABASE_URL format
- **Commands:**
  ```bash
  docker logs <postgres-container>
  netstat -tuln | grep 5432
  ```

**Issue: Build Failures**
- **Solution:** Check build logs, verify Node.js version
- **Commands:**
  ```bash
  coolify logs synthia-backend --follow
  docker build -f Dockerfile.backend .
  ```

**Issue: SSL Certificate Not Provisioning**
- **Solution:** Verify domain DNS, check Coolify SSL settings
- **Commands:**
  ```bash
  nslookup your-domain.com
  certbot certificates
  ```

**Issue: High Memory Usage**
- **Solution:** Increase swap, optimize Node.js settings
- **Commands:**
  ```bash
  free -h
  docker stats
  # Add --max-old-space-size=512 to Node.js start command
  ```

## Post-Migration Optimization

- [ ] **Performance Tuning**
  - [ ] Enable Node.js clustering
  - [ ] Configure Redis cache (optional)
  - [ ] Optimize database queries
  - [ ] Enable CDN for static assets

- [ ] **Cost Optimization**
  - [ ] Right-size VPS instance
  - [ ] Enable resource limits
  - [ ] Set up auto-scaling policies
  - [ ] Monitor monthly costs

- [ ] **Security Hardening**
  - [ ] Enable fail2ban
  - [ ] Configure UFW firewall
  - [ ] Set up SSH key authentication only
  - [ ] Enable automatic security updates

## Success Criteria

✅ Migration is successful when:
- [ ] Application accessible at new URL
- [ ] All API endpoints responding correctly
- [ ] Database queries executing normally
- [ ] No increase in error rates
- [ ] Response times within acceptable limits
- [ ] 99.9% uptime for 7 days
- [ ] All monitoring and alerts configured
- [ ] Team trained on new deployment process
- [ ] Documentation updated
- [ ] Railway decommissioned

## Support Contacts

- **Coolify:** https://coolify.io/docs
- **Hostinger Support:** https://www.hostinger.com/tutorials/vps
- **Community:** https://discord.gg/coolify
- **Synthia Issues:** https://github.com/executiveusa/Synthia-3.0/issues

## Timeline

Recommended migration timeline:

- **Week 1:** Planning and preparation
- **Week 2:** Database migration and testing
- **Week 3:** Application deployment and validation
- **Week 4:** DNS cutover and monitoring
- **Week 5:** Optimization and Railway cleanup

## Notes

- Always test in staging environment first
- Keep Railway running during DNS propagation
- Have rollback plan ready
- Monitor closely for first 48 hours after cutover
- Document any deviations from this checklist

---

**Last Updated:** Auto-generated during Railway Zero-Secrets Deployment setup
**Version:** 1.0
**Status:** Ready for use when free-tier limits are reached
