test_expect_success "setup proc-receive hook (unexpected ref, $PROTOCOL/porcelain)" '
	write_script "$upstream/hooks/proc-receive" <<-EOF
	printf >&2 "# proc-receive hook\n"
	test-tool proc-receive -v \
		-r "ok refs/heads/main"
	EOF
'

# Refs of upstream : main(A)
# Refs of workbench: main(A)  tags/v123
# git push         : (B)                   refs/for/main/topic
test_expect_success "proc-receive: report unexpected ref ($PROTOCOL/porcelain)" '
	test_must_fail git -C workbench push --porcelain origin \
		$B:refs/heads/main \
		HEAD:refs/for/main/topic \
		>out-$test_count 2>&1 &&
	make_user_friendly_and_stable_output <out-$test_count >actual &&
	cat >expect <<-EOF &&
	remote: # pre-receive hook
	remote: pre-receive< <COMMIT-A> <COMMIT-B> refs/heads/main
	remote: pre-receive< <ZERO-OID> <COMMIT-A> refs/for/main/topic
	remote: # proc-receive hook
	remote: proc-receive< <ZERO-OID> <COMMIT-A> refs/for/main/topic
	remote: proc-receive> ok refs/heads/main
	remote: error: proc-receive reported status on unexpected ref: refs/heads/main
	remote: # post-receive hook
	remote: post-receive< <COMMIT-A> <COMMIT-B> refs/heads/main
	To <URL/of/upstream.git>
	     <COMMIT-B>:refs/heads/main    <OID-A>..<OID-B>
	!    HEAD:refs/for/main/topic    [remote rejected] (proc-receive failed to report status)
	Done
	EOF
	test_cmp expect actual &&

	test_cmp_refs -C "$upstream" <<-EOF
	<COMMIT-B> refs/heads/main
	EOF
'

# Refs of upstream : main(B)
# Refs of workbench: main(A)  tags/v123
test_expect_success "cleanup ($PROTOCOL/porcelain)" '
	git -C "$upstream" update-ref refs/heads/main $A
'
