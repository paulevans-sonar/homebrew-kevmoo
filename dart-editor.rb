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
    dev_release_version = '31123'
    dev_base_url = "#{ROOT_URL}/dev/release/#{dev_release_version}"

    url "#{dev_base_url}/editor/darteditor-macos-x64.zip"
    version dev_release_version
    sha1 'c6e06d7c9825db27d8e72acf53e0425afa861cc9'

    resource 'content_shell' do
      url "#{dev_base_url}/dartium/content_shell-macos-ia32-release.zip"
      version dev_release_version
      sha1 '506d988b6ceb80b6e43cd7e85d9870849f42d084'
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

      if name == 'dart'
        bin.install_symlink item
      else
        (bin+name).write shim_script(item)
      end
    end

    if build.with? 'content-shell'
      content_shell_path = prefix+'chromium/content_shell'
      (content_shell_path).install resource('content_shell')

      item = Dir["#{content_shell_path}/Content Shell.app/Contents/MacOS/Content Shell"]

      bin.install_symlink Hash[item, 'content_shell']

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
      void main(List<String> args) {
        if(args.length == 1 && args[0] == 'test message') {
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
