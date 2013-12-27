require 'formula'

class DartEditor < Formula
  ROOT_URL = "https://gsdview.appspot.com/dart-archive/channels"
  release_version = '30798'

  base_url = "#{ROOT_URL}/stable/release/#{release_version}"

  homepage 'http://www.dartlang.org/'
  url "#{base_url}/editor/darteditor-macos-x64.zip"
  version release_version
  sha1 'ef52263ca336956b91d4dcbd8c6cc95a0e2ca499'

  option 'with-content-shell', 'Download and install content_shell -- headless Chromium for testing'

  devel do
    dev_release_version = '31329'
    dev_base_url = "#{ROOT_URL}/dev/release/#{dev_release_version}"

    url "#{dev_base_url}/editor/darteditor-macos-x64.zip"
    version dev_release_version
    sha1 '908b9380749f615c5ef6e546585dba70a15aebc3'

    resource 'content_shell' do
      url "#{dev_base_url}/dartium/content_shell-macos-ia32-release.zip"
      version dev_release_version
      sha1 '5032a37d50f3abc5b0d9dcc54b3c6cbc04137640'
    end
  end

  resource 'content_shell' do
    url "#{base_url}/dartium/content_shell-macos-ia32-release.zip"
    version release_version
    sha1 '24fdb72440ffdf7419979b551435811789dc40b6'
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
