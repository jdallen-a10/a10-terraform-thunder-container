when RULE_INIT {
    set ::CONTENT "<html><head><title>Service Down</title></head><body><h2>Service Temporarily Down</h2><br>
           The Service you are trying to reach is currently not available. Please try again later.</body></html>"
}

when HTTP_REQUEST {
    if { [LB::status pool web-sg] == "down" } {
        log "Server LB selection failed. Sorry Page returned to Client"
        HTTP::respond 503 content $::CONTENT
    }
 }