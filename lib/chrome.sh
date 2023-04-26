chromedriver_install() (
  target="${1:-/usr/local/bin}"
  chrome_version=$(chrome --version | tr -c -d '0-9.')
  curl -LSs https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"${chrome_version%.*}" \
  | xargs -Ichromedriver-version \
    curl -LSs https://chromedriver.storage.googleapis.com/chromedriver-version/chromedriver_linux64.zip \
  | funzip > "$target"/chromedriver && chmod +x "$target"/chromedriver && "$target"/chromedriver --version
)
