# This code should get the glite middleware installed and configured on a node

define glite_node($node_type, $yum_repos, $install_yum_groups="", $inst_cert=""){
    repos{$yum_repos:}
    if $install_yum_groups {
        install_yum_groups{$install_yum_groups:
            subscribe => Repos[$yum_repos],
            require => Repos[$yum_repos],
            before => Config_node["$hostname"],
        }
    }
    config_node{$hostname: 
        node_type => $node_type, 
        inst_cert => $inst_cert,
    }

    service{"yum-updatesd":     # automatic updates are bad, 'mmkay?
        ensure => stopped,
        enable => false,
    }
    


}


define repos(){
    file{"/etc/yum.repos.d/$title.repo":
        source => "puppet://puppet/modules/glider-glite/repos/$title.repo",
    }
}

define install_yum_groups(){
    exec{ $title:
        path    => "/usr/bin:/usr/sbin:/bin",
        command => "yum -y -d0 -e0 groupinstall \"$title\"",
        unless  => "yum grouplist \"$title\" | grep -q '^Installed Groups:$'",
        user    => "root",
    }
}

# to be used on a per-node basis
define config_node($node_type,
        $inst_cert="",
        $glite_conf_dir="/etc/glite"){
   
    file{ "$glite_conf_dir/configure.sh":
        mode        => 755,
        content     => template("glider-glite/configure.sh.erb"),
        require     => File["$glite_conf_dir"]
    }
    exec{ "$glite_conf_dir/configure.sh":
        require     => [File["$glite_conf_dir/configure.sh","$glite_conf_dir/groups.conf",  "$glite_conf_dir/users.conf", "$glite_conf_dir/site-info.def", "$glite_conf_dir/se-list.conf", "$glite_conf_dir/wn-list.conf", "$glite_conf_dir/vo.d"]],
        subscribe   => File["$glite_conf_dir/configure.sh","$glite_conf_dir/groups.conf",  "$glite_conf_dir/users.conf", "$glite_conf_dir/site-info.def", "$glite_conf_dir/se-list.conf", "$glite_conf_dir/wn-list.conf", "$glite_conf_dir/vo.d"],
        refreshonly => true,
        timeout     => "-1",
    }
#   if ($hostname != "ce01") and  ($hostname != "se01") and  ($hostname != "lfc01") and ($hostname != "ui01") and  ($hostname != "apel01"){
#    if ($hostname ==  "/wn\d+/" ) {
#   exec { "yum -y update" :
#     creates => "/root/system_up_to_date",
#     path => ["/usr/bin", "/usr/sbin"],
#     notify => Exec["$glite_conf_dir/configure.sh"],
#     }
#   }


    if $inst_cert == "true" {
        install_cert{"my_cert":
            cert_name => $hostname,
            notify => Exec["$glite_conf_dir/configure.sh"],
            before => Exec["$glite_conf_dir/configure.sh"],
            require => Package["lcg-CA"],
        }
    }
}

# to be used on a per-site basis
define config_site($vos,
        $site_name,
        $site_email,
        $site_domain,
        $site_loc   = "\"Cluj-Napoca, Romania\"",
        $site_web   = "http://www.utcluj.ro",
        $site_lat   = "46.772504",
        $site_long  = "23.58516",
        $ce_host    = "ce01",
        $se_host    = "se01",
        $dpm_host   = "se01",
        $mon_host   = "apel01",
        $lfc_host   = "lfc01",
        $wn_prefix  =   "wn",
        $wn_digits  =   "2",
        $wn_count,
        $mysql_passwd,
        $apel_passwd,
        $cream_passwd,
        $lfc_passwd,
        $dpm_passwd,
        $dpm_info_passwd,
        $glite_conf_dir="/etc/glite")
       {

    package{"java":
        name => "java-1.6.0-openjdk",
        ensure => installed,
    }

    file{ ["$glite_conf_dir"]:
            ensure  => directory,
            mode    => 750,
    }

    file{ "$glite_conf_dir/groups.conf":
        content => template("glider-glite/groups.conf.erb"),
        require => File["$glite_conf_dir"]
    }

    file{ "$glite_conf_dir/users.conf":
        content => template("glider-glite/users.conf.erb"),
        require => File["$glite_conf_dir"]
    }

    file{ "$glite_conf_dir/site-info.def":
        content => template("glider-glite/site-info.def.erb"),
        require => [Package["java"],File["$glite_conf_dir"]],
        subscribe => Service["puppet"], # Puppet needs to be set up for getting facts as modules
        mode    => 600,
    }

    file{ "$glite_conf_dir/se-list.conf": # a single SE works for now
        content => template("glider-glite/se-list.conf.erb"),
        require => File["$glite_conf_dir"]
    }

    file{ "$glite_conf_dir/wn-list.conf":
        content => template("glider-glite/wn-list.conf.erb"),
        require => File["$glite_conf_dir"]
    }
    
    file{ "$glite_conf_dir/vo.d":
        source => "puppet://puppet/glider-glite/vo.d",
        mode    => 755,
        recurse => true,
        ensure => directory
    }
}

define install_cert($cert_name){
    file{"/etc/grid-security/hostcert.pem":
        source => "puppet://puppet/glider-glite/certs/$cert_name/hostcert.pem",
        mode => 644,
        owner => "root",    
    }
    file{"/etc/grid-security/hostkey.pem":
        source => "puppet://puppet/glider-glite/certs/$cert_name/hostkey.pem",
        mode => 400,
        owner => "root",    
    }
}
