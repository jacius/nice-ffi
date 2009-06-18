#--
#
# This file is one part of:
#
# Nice-FFI - Convenience layer atop Ruby-FFI
#
# Copyright (c) 2009 John Croisant
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#++


require 'ffi'


module SDL

  # A Hash of { os_regex => path_templates } pairs describing
  # where to look for libraries on each operating system.
  # 
  # * os_regex is a regular expression that matches FFI::Platform::OS
  #   for the operating system(s) that the path templates are for.
  # 
  # * path_templates is be an Array of one or more strings
  #   describing a template for where a library might be found on this
  #   OS. The string [LIB] will be replaced with the library name.
  #   So "/usr/lib/lib[LIB].so" becomes e.g. "/usr/lib/libSDL_ttf.so".
  # 
  LIBRARY_PATHS = {

    /linux|bsd/  => [ "/usr/local/lib/lib[LIB].so",
                      "/usr/lib/lib[LIB].so",
                      "[LIB]" ],

    /darwin/     => [ "/usr/local/lib/lib[LIB].dylib",
                      "/usr/local/lib/lib[LIB].so",
                      "~/Library/Frameworks/[LIB].framework/[LIB]",
                      "/Library/Frameworks/[LIB].framework/[LIB]",
                      "[LIB]" ],

  }


  # Try to find and load a library (e.g. "SDL_ttf") into an FFI
  # wrapper module (e.g. SDL::Raw::TTF). This method searches in
  # different locations depending on your OS. See LIBRARY_PATHS.
  # 
  # Returns the path to the library that was loaded.
  # 
  # Raises LoadError if it could not find or load the library.
  # 
  def self.load_library( lib_name, wrapper_module )

    os = FFI::Platform::OS

    # Find the regex that matches our OS.
    os_match = LIBRARY_PATHS.keys.find{ |regex|  regex =~ os }

    # Oops, none of the regexs matched our OS.
    if os_match.nil?
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    # Fetch the paths for the matching OS.
    paths = LIBRARY_PATHS[os_match]

    # Fill in for [LIB] and expand the paths.
    paths = paths.collect { |path|
      File.expand_path( path.gsub("[LIB]", lib_name) )
    }

    # Try loading each path until one works.
    loaded = paths.find { |path| 
      begin
        wrapper_module.module_eval {
          ffi_lib path
        }
      rescue LoadError
        false
      else
        true
      end
    }

    # Oops, none of them worked.
    if loaded.nil?
      raise( LoadError, "Could not load library #{lib_name}." )
    else
      # Return the one that did work
      return loaded
    end
  end

end
