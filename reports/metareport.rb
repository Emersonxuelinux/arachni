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

require Options.instance.dir['reports'] + 'metareport/arachni_metareport.rb'

module Reports

#
# Metareport
#
# Creates a file to be used with the Arachni MSF plug-in.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
#
class Metareport < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store = audit_store
        @options     = options
    end

    def run( )

        print_line( )
        print_status( 'Creating file for the Metasploit framework...' )

        msf = []

        @audit_store.issues.each {
            |issue|
            next if !issue.metasploitable

            issue.variations.each {
                |variation|

                if( ( method = issue.method.dup ) != 'post' )
                    url = variation['url'].gsub( /\?.*/, '' )
                else
                    url = variation['url']
                end

                if( issue.elem == 'cookie' || issue.elem == 'header' )
                    method = issue.elem
                end

                # pp issue
                # pp variation['opts']

                params = variation['opts'][:combo]
                next if !params[issue.var]
                params[issue.var] = params[issue.var].gsub( variation['opts'][:injected_orig], 'XXinjectionXX' )

                if method == 'cookie'
                    params[issue.var] = URI.encode( params[issue.var], ';' )
                    cookies = sub_cookie( variation['headers']['request']['cookie'], params )
                    variation['headers']['request']['cookie'] = cookies.dup
                end

                # ap sub_cookie( variation['headers']['request']['cookie'], params )

                msf << ArachniMetareport.new( {
                    :host   => URI( url ).host,
                    :port   => URI( url ).port,
                    :vhost  => '',
                    :ssl    => URI( url ).scheme == 'https',
                    :path   => URI( url ).path,
                    :query  => URI( url ).query,
                    :method => method.upcase,
                    :params => params,
                    :headers=> variation['headers']['request'].dup,
                    :pname  => issue.var,
                    :proof  => variation['regexp_match'],
                    :risk   => '',
                    :name   => issue.name,
                    :description    =>  issue.description,
                    :category   =>  'n/a',
                    :exploit    => issue.metasploitable
                } )
            }

        }

        # pp msf

        outfile = File.new( @options['outfile'], 'w')
        ::YAML.dump( msf, outfile )
        outfile.close

        print_status( 'Saved in \'' + @options['outfile'] + '\'.' )
    end

    def sub_cookie( str, params )
        hash = {}
        str.split( ';' ).each {
            |cookie|
            k,v = cookie.split( '=', 2 )
            hash[k] = v
        }

        return hash.merge( params ).map{ |k,v| "#{k}=#{v}" }.join( ';' )
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Metareport',
            :description    => %q{Creates a file to be used with the Arachni MSF plug-in.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [ Arachni::Report::Options.outfile( '.msf' ) ]

        }
    end

end

end
end
