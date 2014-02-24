require 'formula'
require 'open-uri'
require 'json'

class DartEditor < Formula
  # Manually managed release versions
  release_version = '1' # '31822'
  dev_release_version = '2' # '32844'

  ROOT_URL = "https://gsdview.appspot.com/dart-archive/channels"

  # Versions numbers downloaded from VERSION file of latest
  dev_release_version = JSON.parse(open('#{ROOT_URL}/dev/release/latest/VERSION').read)["version"]
  release_version = JSON.parse(open('#{ROOT_URL}/stable/release/latest/VERSION').read)["version"]

  base_url = "#{ROOT_URL}/stable/release/#{release_version}"

  homepage 'http://www.dartlang.org/'
  url "#{base_url}/editor/darteditor-macos-x64.zip"
  version release_version
  sha1 '7c9bb1ec5475a6af8de5382f34a8a7d2588eb3b4'

  option 'with-content-shell', 'Download and install content_shell -- headless Chromium for testing'

  devel do
    dev_base_url = "#{ROOT_URL}/dev/release/#{dev_release_version}"

    url "#{dev_base_url}/editor/darteditor-macos-x64.zip"
    version dev_release_version
    sha1 'c258b4ca2845b2d83410f6828fadcb8149fbbd05'

    resource 'content_shell' do
      url "#{dev_base_url}/dartium/content_shell-macos-ia32-release.zip"
      version dev_release_version
      sha1 '69a0a7629b4e7f81177a2e0350f3256a888aed57'
    end
  end

  resource 'content_shell' do
    url "#{base_url}/dartium/content_shell-macos-ia32-release.zip"
    version release_version
    sha1 '5382b337bf4ccedd0085b775c87dc934c693f392'
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
