# S3 Static Website Hosting Setup for dbt Docs
## Bucket: radar-dbt-docs-ssen27

### Step 1: Enable Static Website Hosting
1. Go to AWS S3 Console
2. Select bucket: `radar-dbt-docs-ssen27`
3. Click "Properties" tab (right side)
4. Scroll down to "Static website hosting"
5. Click "Edit"
6. Select "Enable"
7. Set:
   - Index document: `index.html`
   - Error document: `index.html` (optional, for SPA routing)
8. Click "Save changes"

### Step 2: Update Bucket Policy (Allow Public Read Access)
1. Go to "Permissions" tab
2. Click "Bucket Policy" 
3. Click "Edit"
4. Paste this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::radar-dbt-docs-ssen27/*"
        }
    ]
}
```

5. Click "Save changes"

### Step 3: Block Public Access Settings (If Needed)
1. Still in "Permissions" tab
2. Click "Block public access (bucket settings)"
3. Uncheck all 4 options (to allow public read):
   - ☐ Block all public access
   - ☐ Block public access to ACLs
   - ☐ Block public access to bucket policies
   - ☐ Block public access via any bucket policy
4. Click "Save changes"
5. Confirm dialog

### Step 4: Upload dbt Docs
Run this command in your terminal:

```bash
cd /Users/sudipsen/Documents/Visual\ Studio_All\ Work/MedTech-CXM/dbt-project/radar/radar/target

aws s3 sync . s3://radar-dbt-docs-ssen27/ \
  --delete \
  --exclude ".git/*" \
  --cache-control "max-age=3600"
```

This uploads the entire `target/` directory (all compiled HTML, CSS, JS, manifest, etc.)

### Step 5: Get Your Public URL
After enabling static website hosting, AWS will provide:
- **Website endpoint**: `http://radar-dbt-docs-ssen27.s3-website-us-east-1.amazonaws.com`
- Replace `us-east-1` with your bucket's region if different

### Step 6: Optional - CloudFront Distribution (Faster, HTTPS, Global)
If you want HTTPS and faster global access:

1. Go to CloudFront Console
2. Create Distribution
3. Origin Settings:
   - Origin: `radar-dbt-docs-ssen27.s3-website-us-east-1.amazonaws.com` (NOT the regular S3 domain)
   - Protocol: HTTP only (S3 website endpoints don't support HTTPS)
4. Default Cache Behavior:
   - Allowed HTTP Methods: GET, HEAD, OPTIONS
   - Cache TTL: 3600 (1 hour)
   - Compress objects: Yes
4. Create Distribution (wait 5-10 min for deployment)
5. Use CloudFront domain: `https://d123abc.cloudfront.net`

---

## Summary of Commands to Run

**After configuring S3 in AWS Console:**

```bash
# Navigate to dbt target directory
cd /Users/sudipsen/Documents/Visual\ Studio_All\ Work/MedTech-CXM/dbt-project/radar/radar

# Upload all dbt docs to S3
aws s3 sync target/ s3://radar-dbt-docs-ssen27/ --delete

# Test the upload
aws s3 ls s3://radar-dbt-docs-ssen27/ --recursive | head -20
```

**Share this URL with friends:**
- Basic: `http://radar-dbt-docs-ssen27.s3-website-<region>.amazonaws.com`
- With CloudFront: `https://d<id>.cloudfront.net`

---

## Key Files That Will Be Uploaded
- `index.html` - Main dbt docs page with DAG
- `manifest.json` - Model metadata
- `graph.gpickle` - Graph data structure
- `catalog.json` - Column catalog
- `semantic_manifest.json` - Semantic layer (if applicable)
- `/compiled/` - SQL files
- `/run/` - Execution details

---

## Update Process (When You Make Changes)

After running `dbt run` or `dbt parse` again:

```bash
aws s3 sync target/ s3://radar-dbt-docs-ssen27/ --delete
```

That's it! No need to re-configure - just re-sync the target directory.
