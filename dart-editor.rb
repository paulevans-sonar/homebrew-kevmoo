require 'formula'

class DartEditor < Formula
  ROOT_URL = "https://gsdview.appspot.com/dart-archive/channels"
  release_version = '30188'

  base_url = "#{ROOT_URL}/stable/release/#{release_version}"

  homepage 'http://www.dartlang.org/'
  url "#{base_url}/editor/darteditor-macos-x64.zip"
  version release_version
  sha1 'e6eb7099ea883d2d6790c006dcb575245cf89031'

  option 'with-content-shell', 'Download and install content_shell -- headless Chromium for testing'

  devel do
    dev_release_version = '30338'
    dev_base_url = "#{ROOT_URL}/dev/release/#{dev_release_version}"

    url "#{dev_base_url}/editor/darteditor-macos-x64.zip"
    version dev_release_version
    sha1 'f41242671f4e11ef735d7c6d40c33507a57c6c7a'

    resource 'content_shell' do
      url "#{dev_base_url}/dartium/content_shell-macos-ia32-release.zip"
      version dev_release_version
      sha1 '681fb723f4d4b2eeec9ecc0563a5d530ad25f3fa'
    end
  end

  resource 'content_shell' do
    url "#{base_url}/dartium/content_shell-macos-ia32-release.zip"
    version release_version
    sha1 '4d7514c7d83ccb4a442afb4a71bde7d1c020d688'
  end

  depends_on :arch => :x86_64
  conflicts_with 'dart'

  def shim_script target
    <<-EOS.undent
      #!/bin/bash
      export DART_SDK=#{prefix}/dart-sdk
      exec "#{target}" "$@"
    EOS
  end

  def install
    prefix.install Dir['*']

    items = Dir[prefix+'dart-sdk/bin/*'].select { |f| File.file? f }

    items.each do |item|
      name = File.basename item
      (bin+name).write shim_script(item)
    end

    if build.with? 'content-shell'
      content_shell_path = prefix+'chromium/content_shell'
      (content_shell_path).install resource('content_shell')

      puts content_shell_path

      item = Dir["#{content_shell_path}/Content Shell.app/Contents/MacOS/Content Shell"]

      (bin+'content_shell').write shim_script(item)

    end

  end

  def caveats; <<-EOS.undent
    DartEditor.app was installed in:
      #{installed_prefix}

    To symlink into ~/Applications, you can do:
      brew linkapps
    EOS
  end

  def test
    mktemp do
      (Pathname.pwd+'sample.dart').write <<-EOS.undent
      import 'dart:io';
      void main() {
        Options opts = new Options();
        if(opts.arguments.length == 1 && opts.arguments[0] == 'test message') {
          exit(0);
        } else {
          exit(1);
        }
      }
      EOS

      system "#{bin}/dart sample.dart 'test message'"
    end
  end
end
