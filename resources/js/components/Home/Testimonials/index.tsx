import React from "react";
import Slider from "react-slick";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import { Icon } from "@iconify/react/dist/iconify.js";

const TestimonialData = [
    {
        name: "John Doe",
        profession: "Student",
        comment: "Excellent practice materials!",
        imgSrc: "images/testimonials/user1.png",
        rating: 5
    },
    {
        name: "Jane Smith",
        profession: "IELTS Candidate",
        comment: "The mock tests are very realistic.",
        imgSrc: "images/testimonials/user2.png",
        rating: 4.5
    }
];

const Testimonial = () => {

    const settings = {
        dots: true,
        dotsClass: "slick-dots",
        infinite: true,
        slidesToShow: 3,
        slidesToScroll: 2,
        arrows: false,
        autoplay: true,
        cssEase: "linear",
        responsive: [
            {
                breakpoint: 1200,
                settings: {
                    slidesToShow: 3,
                    slidesToScroll: 1,
                    infinite: true,
                    dots: false
                }
            },
            {
                breakpoint: 800,
                settings: {
                    slidesToShow: 2,
                    slidesToScroll: 1,
                    infinite: true,
                    dots: false
                }
            },
            {
                breakpoint: 600,
                settings: {
                    slidesToShow: 1,
                    slidesToScroll: 1,
                    infinite: true,
                    dots: false
                }
            }
        ]
    };

    const renderStars = (rating: number) => {
        const fullStars = Math.floor(rating);
        const halfStars = rating % 1 >= 0.5 ? 1 : 0;
        const emptyStars = 5 - fullStars - halfStars;

        return (
            <>
                {Array(fullStars).fill(<Icon icon="tabler:star-filled" className="text-amber-500 text-xl inline-block" />)}
                {halfStars > 0 && <Icon icon="tabler:star-half-filled" className="text-amber-500 text-xl inline-block" />}
                {Array(emptyStars).fill(<Icon icon="tabler:star-filled" className="text-muted-foreground text-xl inline-block" />)}
            </>
        );
    };

    return (
        <section id="testimonial">
            <div className='container mx-auto lg:max-w-screen-xl md:max-w-screen-md px-4'>
                <Slider {...settings}>
                    {TestimonialData.map((items, i) => (
                        <div key={i}>
                            <div className={`glass rounded-[22px] m-4 p-5 my-20 relative`}>
                                <div className="absolute top-[-45px]">
                                    <img src={`/${items.imgSrc}`}
                                        alt={items.name} width={100} height={100} className="inline-block" />
                                </div>
                                <h4 className='text-base font-normal text-muted-foreground my-4'>{items.comment}</h4>
                                <div className="flex justify-between items-center">
                                    <div>
                                        <h3 className='text-lg font-medium text-foreground pt-4 pb-2'>{items.name}</h3>
                                        <h3 className='text-sm font-normal text-muted-foreground pb-2'>{items.profession}</h3>
                                    </div>
                                    <div className="flex">
                                        {renderStars(items.rating)}
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </Slider>
            </div>
        </section>
    );
};

export default Testimonial;
