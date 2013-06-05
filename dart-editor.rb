require 'formula'

class Requires64Bit < Requirement
  def message
    "Requires 64-bit OS"
  end

  def satisfied?
    MacOS.prefer_64_bit?
  end

  def fatal?
    true
  end
end

class RequiresNoDart < Requirement
  def message
    <<-EOS.undent
    You must uninstall the 'dart' formula before continuing.
    This formula includes a superset of the functionality in 'dart'.
    EOS
  end

  def satisfied?
    not Formula.factory('dart').installed?
  end

  def fatal?
    true
  end
end

class DartEditor < Formula
  homepage 'http://www.dartlang.org/'
  url 'https://gsdview.appspot.com/dart-editor-archive-integration/23552/darteditor-macos-64.zip'
  version '23552'
  sha1 '077d07d108470e4486e73d07d2c8a1359d57c4e7'

  devel do
    url 'https://gsdview.appspot.com/dart-editor-archive-trunk/23346/darteditor-macos-64.zip'
    version '23346'
    sha1 '65ccba02cf221b323971e48f4c32e63c11c17980'
  end

  depends_on Requires64Bit
  depends_on RequiresNoDart

  def shim_script target
    <<-EOS.undent
      #!/bin/bash
      export DART_SDK=#{prefix+'dart-sdk'}
      exec "#{target}" "$@"
    EOS
  end

  def install
    prefix.install Dir['*']

    items = Dir[prefix+'dart-sdk/bin/*']
    items.concat Dir[prefix+'chromium/DumpRenderTree.app/Contents/MacOS/DumpRenderTree']
    items.concat Dir[prefix+'chromium/Content Shell.app/Contents/MacOS/Content Shell']

    items.each do |item|
      name = File.basename item
      (bin+name).write shim_script(item)
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
