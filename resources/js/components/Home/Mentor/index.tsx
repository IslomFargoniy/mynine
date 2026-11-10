import React from "react";
import Slider from "react-slick";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";

const MentorData = [
    { name: "Sheroziy", profession: "Senior Developer", imgSrc: "images/mentor/user1.png" },
    { name: "Doniyor", profession: "IELTS Instructor", imgSrc: "images/mentor/user2.png" },
    { name: "Azizbek", profession: "Designer", imgSrc: "images/mentor/user3.png" },
];

const Mentor = () => {

    const settings = {
        dots: false,
        infinite: true,
        slidesToShow: 3,
        slidesToScroll: 1,
        arrows: false,
        autoplay: true,
        cssEase: "linear",
        responsive: [
            {
                breakpoint: 1200,
                settings: {
                    slidesToShow: 3,
                }
            },
            {
                breakpoint: 1000,
                settings: {
                    slidesToShow: 2,
                }
            },
            {
                breakpoint: 530,
                settings: {
                    slidesToShow: 1,
                }
            }
        ]
    };

    return (
        <section className="py-10" id="mentor" >
            <div className='container mx-auto lg:max-w-screen-xl md:max-w-screen-md px-4 relative'>
                <h2 className="text-foreground text-5xl font-semibold">Meet with our <br /> mentor.</h2>

                <Slider {...settings}>
                    {MentorData.map((items, i) => (
                        <div key={i}>
                            <div className='m-3 py-14 md:my-10 text-center'>
                                <div className="relative">
                                    <img src={`/${items.imgSrc}`} alt="user-image" width={306} height={306} className="inline-block m-auto" />
                                    <div className="absolute right-[84px] bottom-[102px] glass-subtle rounded-full p-4">
                                        <img src={`/images/mentor/linkedin.svg`} alt="linkedin-image" width={25} height={24} />
                                    </div>
                                </div>
                                <div className="-mt-10">
                                    <h3 className='text-2xl font-semibold text-foreground'>{items.name}</h3>
                                    <h4 className='text-lg font-normal text-muted-foreground pt-2'>{items.profession}</h4>
                                </div>
                            </div>
                        </div>
                    ))}
                </Slider>
            </div>
        </section>
    );
}

export default Mentor