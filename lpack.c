/*
* lpack.c
* a Lua library for packing and unpacking binary data
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 29 Jun 2007 19:27:20
* This code is hereby placed in the public domain.
* with contributions from Ignacio Castaño <castanyo@yahoo.es> and
* Roberto Ierusalimschy <roberto@inf.puc-rio.br>.
*/

#define	OP_ZSTRING	'z'		/* zero-terminated string */
#define	OP_BSTRING	'p'		/* string preceded by length byte */
#define	OP_WSTRING	'P'		/* string preceded by length word */
#define	OP_SSTRING	'a'		/* string preceded by length size_t */
#define	OP_STRING	'A'		/* string */
#define	OP_FLOAT	'f'		/* float */
#define	OP_DOUBLE	'd'		/* double */
#define	OP_NUMBER	'n'		/* Lua number */
#define	OP_CHAR		'c'		/* char */
#define	OP_BYTE		'b'		/* byte = unsigned char */
#define	OP_SHORT	'h'		/* short */
#define	OP_USHORT	'H'		/* unsigned short */
#define	OP_INT		'i'		/* int */
#define	OP_UINT		'I'		/* unsigned int */
#define	OP_LONG		'l'		/* long */
#define OP_ULONG  'L'   /* unsigned long */
#define OP_UINT64  'U'   /* uint64 */
#define	OP_INT64	'u'		/* int64 */
#define OP_UINT64TONUMBER  'Y'   /* uint64 */
#define OP_INT64TONUMBER  'y'   /* int64 */
#define OP_UINT64STRING  'O'   /* string convert to unsigned long long */
#define OP_INT64STRING  'o'   /* string  convert to long long */
#define	OP_LITTLEENDIAN	'<'		/* little endian */
#define	OP_BIGENDIAN	'>'		/* big endian */
#define	OP_NATIVE	'='		/* native endian */

#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

#include "tolua.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static int _DefaultSwap = (int)OP_BIGENDIAN;

static void badcode(lua_State *L, int c)
{
 char s[]="bad code `?'";
 s[sizeof(s)-3]=c;
 luaL_argerror(L,1,s);
}

static int doendian(int c)
{
 int x=1;
 int e=*(char*)&x;
 if (c==OP_LITTLEENDIAN) return !e;
 if (c==OP_BIGENDIAN) return e;
 if (c==OP_NATIVE) return 0;
 return 0;
}

static void doswap(int swap, void *p, size_t n)
{
 if (swap)
 {
  char *a=p;
  int i,j;
  for (i=0, j=n-1, n=n/2; n--; i++, j--)
  {
   char t=a[i]; a[i]=a[j]; a[j]=t;
  }
 }
}

#define UNPACKNUMBER(OP,T)		\
   case OP:				\
   {					\
    T a;				\
    int m=sizeof(a);			\
    if (i+m>len) goto done;		\
    memcpy(&a,s+i,m);			\
    i+=m;				\
    doswap(swap,&a,m);			\
    lua_pushnumber(L,(lua_Number)a);	\
    ++n;				\
    break;				\
   }

#define UNPACKINTERGER(OP,T)    \
   case OP:       \
   {          \
    T a;        \
    int m=sizeof(a);      \
    if (i+m>len) goto done;   \
    memcpy(&a,s+i,m);     \
    i+=m;       \
    doswap(swap,&a,m);      \
    lua_pushinteger(L,(lua_Integer)a);  \
    ++n;        \
    break;        \
   }

#define UNPACKSTRING(OP,T)		\
   case OP:				\
   {					\
    T l;				\
    int m=sizeof(l);			\
    if (i+m>len) goto done;		\
    memcpy(&l,s+i,m);			\
    doswap(swap,&l,m);			\
    if (i+m+l>len) goto done;		\
    i+=m;				\
    lua_pushlstring(L,s+i,l);		\
    i+=l;				\
    ++n;				\
    break;				\
   }

static int l_unpack(lua_State *L) 		/** unpack(s,f,[init]) */
{
 size_t len;
 const char *s=luaL_checklstring(L,1,&len);
 const char *f=luaL_checkstring(L,2);
 int i=luaL_optnumber(L,3,1)-1;
 int n=0;
 int swap=doendian(_DefaultSwap);
 lua_pushnil(L);
 while (*f)
 {
  int c=*f++;
  int N=1;
  if (isdigit(*f)) 
  {
   N=0;
   while (isdigit(*f)) N=10*N+(*f++)-'0';
   if (N==0 && c==OP_STRING) { lua_pushliteral(L,""); ++n; }
  }
  while (N--) switch (c)
  {
   case OP_LITTLEENDIAN:
   case OP_BIGENDIAN:
   case OP_NATIVE:
   {
    swap=doendian(c);
    N=0;
    break;
   }
   case OP_STRING:
   {
    ++N;
    if (i+N>len) goto done;
    lua_pushlstring(L,s+i,N);
    i+=N;
    ++n;
    N=0;
    break;
   }
   case OP_ZSTRING:
   {
    size_t l;
    if (i>=len) goto done;
    l=strlen(s+i);
    lua_pushlstring(L,s+i,l);
    i+=l+1;
    ++n;
    break;
   }
   case OP_INT64STRING:
   {
    long long a;
    int m=sizeof(a);
    if (i+m>len) goto done;
    memcpy(&a,s+i,m);
    i+=m;
    doswap(swap,&a,m);
    char temp[64];
    sprintf(temp, "%I64d", a);    
    lua_pushstring(L, temp);
    ++n;
    break;
   }
   case OP_UINT64STRING:
   {
    unsigned long long a;
    int m=sizeof(a);
    if (i+m>len) goto done;
    memcpy(&a,s+i,m);
    i+=m;
    doswap(swap,&a,m);
    char temp[64];
    sprintf(temp, "%I64u", a);    
    lua_pushstring(L, temp);
    ++n;
    break;
   }
#if LUA_VERSION_NUM < 503
   case OP_INT64:
   {
    long long a;
    int m=sizeof(a);
    if (i+m>len) goto done;
    memcpy(&a,s+i,m);
    i+=m;
    doswap(swap,&a,m);
    tolua_pushint64(L,(int64_t)a);
    ++n;        
    break;
   }
   case OP_UINT64:
   {
    unsigned long long a;
    int m=sizeof(a);
    if (i+m>len) goto done;
    memcpy(&a,s+i,m);
    i+=m;
    doswap(swap,&a,m);
    tolua_pushuint64(L,(uint64_t)a);
    ++n;        
    break;
   }
#else
   UNPACKINTERGER(OP_INT64, long long)
   UNPACKINTERGER(OP_UINT64, unsigned long long)
#endif
   UNPACKSTRING(OP_BSTRING, unsigned char)
   UNPACKSTRING(OP_WSTRING, unsigned short)
   UNPACKSTRING(OP_SSTRING, size_t)
   UNPACKNUMBER(OP_NUMBER, lua_Number)
   UNPACKNUMBER(OP_DOUBLE, double)
   UNPACKNUMBER(OP_FLOAT, float)
   UNPACKINTERGER(OP_CHAR, char)
   UNPACKINTERGER(OP_BYTE, unsigned char)
   UNPACKINTERGER(OP_SHORT, short)
   UNPACKINTERGER(OP_USHORT, unsigned short)
   UNPACKINTERGER(OP_INT, int)
   UNPACKINTERGER(OP_UINT, unsigned int)
   UNPACKINTERGER(OP_LONG, long)
   UNPACKINTERGER(OP_ULONG, unsigned long)
   UNPACKNUMBER(OP_INT64TONUMBER, long long)
   UNPACKNUMBER(OP_UINT64TONUMBER, unsigned long long)
   case ' ': case ',':
    break;
   default:
    badcode(L,c);
    break;
  }
 }
done:
 lua_pushnumber(L,i+1);
 lua_replace(L,-n-2);
 return n+1;
}

#define PACKNUMBER(OP,T)			\
   case OP:					\
   {						\
    T a=(T)luaL_checknumber(L,i++);		\
    doswap(swap,&a,sizeof(a));			\
    luaL_addlstring(&b,(void*)&a,sizeof(a));	\
    break;					\
   }

#define PACKINTERGER(OP,T)      \
   case OP:         \
   {            \
    T a=(T)luaL_checkinteger(L,i++);   \
    doswap(swap,&a,sizeof(a));      \
    luaL_addlstring(&b,(void*)&a,sizeof(a));  \
    break;          \
   }

#define PACKSTRING(OP,T)			\
   case OP:					\
   {						\
    size_t l;					\
    const char *a=luaL_checklstring(L,i++,&l);	\
    T ll=(T)l;					\
    doswap(swap,&ll,sizeof(ll));		\
    luaL_addlstring(&b,(void*)&ll,sizeof(ll));	\
    luaL_addlstring(&b,a,l);			\
    break;					\
   }

static int l_pack(lua_State *L) 		/** pack(f,...) */
{
 int i=2;
 const char *f=luaL_checkstring(L,1);
 int swap=doendian(_DefaultSwap);
 luaL_Buffer b;
 luaL_buffinit(L,&b);
 while (*f)
 {
  int c=*f++;
  int N=1;
  if (isdigit(*f)) 
  {
   N=0;
   while (isdigit(*f)) N=10*N+(*f++)-'0';
  }
  while (N--) switch (c)
  {
   case OP_LITTLEENDIAN:
   case OP_BIGENDIAN:
   case OP_NATIVE:
   {
    swap=doendian(c);
    N=0;
    break;
   }
   case OP_STRING:
   case OP_ZSTRING:
   {
    size_t l;
    const char *a=luaL_checklstring(L,i++,&l);
    luaL_addlstring(&b,a,l+(c==OP_ZSTRING));
    break;
   }
   case OP_INT64STRING:
   {
    const char *n = luaL_checkstring(L, i++);
    long long a = strtoll(n, NULL, 10);
    doswap(swap,&a,sizeof(a));
    luaL_addlstring(&b,(void*)&a,sizeof(a));
    break;
   }
   case OP_UINT64STRING:
   {
    const char *n = luaL_checkstring(L, i++);
    unsigned long long a = strtoull(n, NULL, 10);
    doswap(swap,&a,sizeof(a));
    luaL_addlstring(&b,(void*)&a,sizeof(a));
    break;
   }
#if LUA_VERSION_NUM < 503
   case OP_INT64:
   {
    int64_t n = tolua_toint64(L, i++);
    long long a = (long long)n;
    doswap(swap,&a,sizeof(a));
    luaL_addlstring(&b,(void*)&a,sizeof(a));
    break;
   }
   case OP_UINT64:
   {
    uint64_t n = tolua_touint64(L, i++);
    unsigned long long a = (unsigned long long)n;
    doswap(swap,&a,sizeof(a));
    luaL_addlstring(&b,(void*)&a,sizeof(a));
    break;
   }
#else
   PACKINTERGER(OP_INT64, long long)
   PACKINTERGER(OP_UINT64, unsigned long long)
#endif
   PACKSTRING(OP_BSTRING, unsigned char)
   PACKSTRING(OP_WSTRING, unsigned short)
   PACKSTRING(OP_SSTRING, size_t)
   PACKNUMBER(OP_NUMBER, lua_Number)
   PACKNUMBER(OP_DOUBLE, double)
   PACKNUMBER(OP_FLOAT, float)
   PACKINTERGER(OP_CHAR, char)
   PACKINTERGER(OP_BYTE, unsigned char)
   PACKINTERGER(OP_SHORT, short)
   PACKINTERGER(OP_USHORT, unsigned short)
   PACKINTERGER(OP_INT, int)
   PACKINTERGER(OP_UINT, unsigned int)
   PACKINTERGER(OP_LONG, long)
   PACKINTERGER(OP_ULONG, unsigned long)
   PACKNUMBER(OP_INT64TONUMBER, long long)
   PACKNUMBER(OP_UINT64TONUMBER, unsigned long long)
   case ' ': case ',':
    break;
   default:
    badcode(L,c);
    break;
  }
 }
 luaL_pushresult(&b);
 return 1;
}

static int l_DefaultSwap(lua_State *L) 
{
  const char *f=luaL_checkstring(L,1);
  _DefaultSwap = *f;
  // _DefaultSwap = luaL_checkinteger(L, 1);
  return 0;
}

static const luaL_Reg R[] =
{
	{"pack",	l_pack},
  {"unpack",  l_unpack},
  {"set_DefaultSwap", l_DefaultSwap},
	{NULL,	NULL}
};

int luaopen_pack(lua_State *L)
{
#if LUA_VERSION_NUM < 502
  luaL_register(L, "lua_pack", R);
#else
  luaL_newlib(L, R);
#endif
  return 1;
// #ifdef USE_GLOBALS
//  lua_register(L,"bpack",l_pack);
//  lua_register(L,"bunpack",l_unpack);
// #else
//  luaL_openlib(L, LUA_STRLIBNAME, R, 0);
// #endif
//  return 0;
}
