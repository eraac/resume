#!/bin/bash

BASE_URL="http://localhost:8080"
ERRORS=0

echo "Starting NGINX Integration Tests..."
echo "-----------------------------------"

check_result() {
    if [ "$1" -eq 0 ]; then
        echo "✅ PASS: $2"
    else
        echo "❌ FAIL: $2"
        ERRORS=$((ERRORS + 1))
    fi
}

# Test 1: Content Negotiation serves JSON
RESULT=$(curl -s -H "Accept: application/json" -o /dev/null -w "%{http_code} %{content_type}" "$BASE_URL")
[[ "$RESULT" == "200 application/json" ]]
check_result $? "Accept header serves JSON"

# Test 2: Disallowed HTTP methods are blocked (POST)
HTTP_STATUS=$(curl -s -X POST -o /dev/null -w "%{http_code}" "$BASE_URL")
[[ "$HTTP_STATUS" == "403" ]]
check_result $? "POST requests are blocked (403)"

# Test 3: Hidden files are blocked
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/.env")
[[ "$HTTP_STATUS" == "403" ]]
check_result $? "Hidden files are blocked (403)"

# Test 4 & 5: Security Headers and Server Tokens
# Dump headers into a temporary file
curl -s -I "$BASE_URL" > /tmp/headers.txt

grep -qi "X-Frame-Options: SAMEORIGIN" /tmp/headers.txt && \
grep -qi "X-Content-Type-Options: nosniff" /tmp/headers.txt && \
grep -qi "X-XSS-Protection: 1; mode=block" /tmp/headers.txt && \
grep -qi "Referrer-Policy: no-referrer-when-downgrade" /tmp/headers.txt && \
grep -qi "Content-Security-Policy: default-src 'self';" /tmp/headers.txt
check_result $? "Security headers are present"

# Server token should be EXACTLY "Server: nginx" with no version number
grep -qi "^Server: nginx\r$" /tmp/headers.txt
check_result $? "Server tokens are hidden"

rm /tmp/headers.txt

echo "-----------------------------------"
if [ "$ERRORS" -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "🔥 $ERRORS test(s) failed."
    exit 1
fi
