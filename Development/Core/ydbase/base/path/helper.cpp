#include <base/path/helper.h>

namespace base { namespace path {
	bool equal(fs::path const& lhs, fs::path const& rhs)
	{
		fs::path lpath = fs::absolute(lhs);
		fs::path rpath = fs::absolute(rhs);
		const fs::path::value_type* l(lpath.c_str());
		const fs::path::value_type* r(rpath.c_str());
		while ((towlower(*l) == towlower(*r) || (*l == L'\\' && *r == L'/') || (*l == L'/' && *r == L'\\')) && *l)
		{ 
			++l; ++r; 
		}
		return *l == *r;
	}
}}
