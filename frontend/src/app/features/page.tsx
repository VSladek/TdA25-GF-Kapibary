export default function Features() {
  const features = ["F-000"];
  return (
    <>
      {features.map((feature, index) => (
        <div key={index}>{feature}</div>
      ))}
    </>
  );
}
