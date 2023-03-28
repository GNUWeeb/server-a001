#include <signal.h>
#include <unistd.h>

int main(void)
{
	struct sigaction a = { .sa_handler = SIG_IGN };

	if (sigaction(SIGCHLD, &a, NULL) < 0)
		return 1;

	while (1)
		sleep(1000000);

	return 0;
}
