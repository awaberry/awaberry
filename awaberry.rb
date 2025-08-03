class Awaberry < Formula
  desc "AwaBerry installer for macOS"
  homepage "https://www.awaberry.com"
  url "https://github.com/awaberry/awaberry/macbrewinstaller.sh"
  version "1.0.0"
  sha256 "2bc54bc982bc601ec455949aa29cde1477ac58159a640559ab56302e2d65abe2"

  depends_on "screen"
  depends_on "jq"
  depends_on "curl"
  depends_on "openssl"
  depends_on "zip"
  depends_on "unzip"
  depends_on "openjdk@17"

  def install
    bin.install "macbrewinstaller.sh" => "awaberry"
    chmod 0755, bin/"awaberry"
  end

  plist_options manual: "#{HOMEBREW_PREFIX}/bin/awaberry"

  def plist
      <<~EOS
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.awabon.awaberryclient</string>
            <key>ProgramArguments</key>
            <array>
              <string>java</string>
              <string>-Xmx64m</string>
              <string>-cp</string>
              <string>awaberryclient.jar:lib/*</string>
              <string>com.awabon.client.mainapp.MainAppAwaberryClient</string>
            </array>
            <key>WorkingDirectory</key>
            <string>$HOME/awaberry/awaberryclient/app</string>
            <key>RunAtLoad</key>
            <true/>
            <key>StandardOutPath</key>
            <string>$HOME/awaberryclient/.awaberrydata/execution.log</string>
            <key>StandardErrorPath</key>
            <string>$HOME/awaberry/execution.log</string>
          </dict>
        </plist>
      EOS
    end

  test do
    if File.exist?('>$HOME/awaberry/.awaberrydata/execution.log')
      puts "Log file for awaberry exists - client is up."
    else
      puts "File does not exist."
    end
  end
end