#include <stdio.h>
#include <stdlib.h>


int search_in_table(char t[], char c)
{
	int i;
	for (i = 0; i < 16; i++)
	{
		if (t[i] == c)
			break;
	}
	if (i == 16)
		return 0;
	else
		return i;
}

int main()
{
	char hex[2], color;
	char t[] = "0123456789ABCDEF";
	int i;
	int x, y;
	int r, c;
	unsigned char *pasc;
	for (i = 0; i < 2; i++) /* 输入2位十六进制ASCII码 */
	{
		hex[i] = getchar();
		if (hex[i] >= 'a' && hex[i] <= 'f')
			hex[i] -= 32; /* 小写转大写 */
	}
	i = (search_in_table(t, hex[0]) << 4) + search_in_table(t, hex[1]);
	/* 2位十六进制字符串转成数值 */
	printf("%d \n", i);
	system("pause");



}
