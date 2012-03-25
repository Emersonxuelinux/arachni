=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Modules

#
# Backup file discovery module.
#
# Appends common backup extesions to the filename of the page under audit<br/>
# and checks for its existence.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.2.1
#
#
class BackupFiles < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        # to keep track of the requests and not repeat them
        @@__audited ||= Set.new

        @@__extensions ||=[]
        return if !@@__extensions.empty?

        read_file( 'extensions.txt' ) {
            |file|
            @@__extensions << file
        }
    end

    def run
        path = get_path( @page.url )
        return if @@__audited.include?( path )

        filename = File.basename( URI( normalize_url( @page.url ) ).path )

        print_status( "Scanning..." )

        if( !filename  )
            print_info( 'Backing out. ' +
              'Can\'t extract filename from url: ' + @page.url )
            return
        end

        @@__extensions.each {
            |ext|

            #
            # Test for the existance of the file + extension.
            #

            file = ext % filename # Example: index.php.bak
            check!( path, file )

            cfile = ext % filename.gsub( /\.(.*)/, '' ) # Example: index.bak
            check!( path, file ) if file != cfile
        }

        @@__audited << path
    end

    def check!( path, file )

        url = path + file

        print_status( "Checking for #{url}" )

        log_remote_file_if_exists( url ) {
            |res|
            print_ok( "Found #{file} at " + res.effective_url )
        }
    end

    def self.info
        {
            :name           => 'BackupFiles',
            :description    => %q{Tries to find sensitive backup files.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.2.1',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A backup file exists on the server.},
                :description => %q{ The server response indicates that a file matching
                    the name of a common naming scheme for file backups can be publicly accessible.
                    A developer has probably forgotten to remove this file after testing.
                    This can lead to source code disclosure and privileged information leaks.},
                :tags        => [ 'path', 'backup', 'file', 'discovery' ],
                :cew         => '530',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
