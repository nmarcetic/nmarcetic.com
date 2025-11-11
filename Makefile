SHELL := /bin/bash
AWS := aws
AWS_PROFILE := nmarcetic
HUGO := hugo
PUBLIC_FOLDER := public/
S3_BUCKET = s3://nmarcetic.com/
CLOUDFRONT_ID := E2AB1Y10GKZAVR

DEPLOY_LOG := deploy.log

.ONESHELL:

build-production:
	HUGO_ENV=production $(HUGO)

deploy: build-production
	echo "Copying files to server..."
	$(AWS) s3 sync $(PUBLIC_FOLDER) $(S3_BUCKET) --size-only --delete | tee -a $(DEPLOY_LOG) --profile $(AWS_PROFILE)
	# filter files to invalidate cdn
	grep "upload\|delete" $(DEPLOY_LOG) | sed -e "s|.*upload.*to $(S3_BUCKET)|/|" | sed -e "s|.*delete: $(S3_BUCKET)|/|" | sed -e 's/index.html//' | sed -e 's/\(.*\).html/\1/' | tr '\n' ' ' | xargs aws cloudfront create-invalidation --distribution-id $(CLOUDFRONT_ID) --paths --profile $(AWS_PROFILE)
