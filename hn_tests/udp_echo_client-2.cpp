#include <hn/lib.hpp>

struct hnMain_impl
{
	ff::UdpSocket c;

	struct tb_impl
	{
		typedef tb_impl self;
		template <typename t2>
		static ff::IO<void> t4(t2 end_time)
		{
			return ff::print(0);
		};
		template <typename t5>
		static ff::IO<void> t3(t5 reply)
		{
			return ff::bind<int, void>(ff::time_msec, &self::t4<int>);
		};
	};

	template <typename t1>
	ff::IO<void> tb(t1 start_time)
	{
		typedef tb_impl local;
		return ff::bind<std::string, void>(ff::udp_receive(c), &local::t3<std::string>);
	};
};

ff::IO<void> hnMain()
{
	typedef hnMain_impl local;
	local impl = { ff::udp_connect("localhost", 99) };
	return ff::forever(ff::bind<int, void>(ff::time_msec, hn::bind(impl, &local::tb<int>)));
};
