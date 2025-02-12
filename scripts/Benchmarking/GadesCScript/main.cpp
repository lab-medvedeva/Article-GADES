#include <iostream>
#include <armadillo>
#include <arrayfire.h>
#include <cstdlib>
#include <chrono>
#include <fstream>
#include <string>
#include <complex>
#include "rapidcsv.hpp"

arma::mat arma_dist_euclid(const arma::mat& a)
{
  arma::mat res(a.n_cols, a.n_cols, arma::fill::none);
  for (size_t i = 0; i < a.n_cols; ++i)
  {
    res.row(i) = arma::vecnorm(a.each_col() - a.col(i), 2, 0);
  }
  return res;
}

arma::mat arma_dist_pearson(const arma::mat& a)
{
  return arma::cor(a);
}

// arma doesn't suppot kendall

static af::array square(const af::array& a)
{
  return a * a;
}

af::array af_eucl_dist1(const af::array& a)
{
  // int feat_len = a.dims(0); // Same as b.dims(0);
  int alen = a.dims(1);

  af::array dist_mat = af::constant(0, alen, alen);
  for (int jj = 0; jj < alen; jj++)
  {
    af::array bvec = a(af::span, jj);
    af::array bvec_tiled = af::tile(bvec, 1, alen);
    af::array sad = af::sqrt(af::sum(square(bvec_tiled - a)));
    dist_mat(af::span, jj) = sad.T();
  }

  return dist_mat;
}

// More memory intensive than dist1, but faster
af::array af_eucl_dist2(const af::array& a)
{
  int feat_len = a.dims(0);
  int alen = a.dims(1);

  af::array a_mod = a;
  af::array b_mod = af::moddims(a, feat_len, 1, alen);

  af::array a_tiled = af::tile(a_mod, 1, 1, alen);
  af::array b_tiled = af::tile(b_mod, 1, alen, 1);

  af::array dist_mod = af::sqrt(af::sum(square(a_tiled - b_tiled)));
  af::array dist_mat = af::moddims(dist_mod, alen, alen);

  return dist_mat;
}

af::array af_pearson_dist(const af::array& a)
{
  int feat_len = a.dims(0);
  int alen = a.dims(1);

  af::array mean_a = af::sum(a, 0) / feat_len;
  af::array a_diff = a - af::tile(mean_a, feat_len, 1);

  af::array a_norm = af::sqrt(af::sum(square(a_diff), 0));

  af::array res = af::matmul(af::transpose(a_diff), a_diff);
  res /= af::tile(a_norm, alen, 1);
  res /= af::tile(af::moddims(a_norm, alen, 1), 1, alen);

  return res;
}

template <typename Func>
std::vector<double> iterate(int times, Func function)
{
  std::vector<double> measurements(times);
  for (int i = 0; i < times; ++i)
  {
    auto begin = std::chrono::high_resolution_clock::now();
    function();
    auto end = std::chrono::high_resolution_clock::now();
    measurements[i] = std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count();
    measurements[i] /= 1e6;
  }
  return measurements;
}

void validate(int argc, char* argv[])
{
  if (argc != 6)
  {
    fprintf(stderr, "Expected 5 arguments, got %d\n", argc - 1);
    std::exit(1);
  }
  std::string method = argv[2];
  std::vector valid_methods = {"af_cpu", "af_oneapi", "af_opencl", "arma"};
  if (std::all_of(
        valid_methods.begin(), valid_methods.end(), [&](auto curr) { return method != curr; }))
  {
    std::string methods;
    for (auto curr : valid_methods)
    {
      methods += curr;
      methods += ", ";
    }
    fprintf(stderr, "Expected one of [%s] got \"%s\" instead\n", methods.c_str(), argv[2]);
    std::exit(1);
  }
  std::string metric = argv[4];
  std::vector valid_metrics = {"euclid", "pearson"};
  if (std::all_of(
        valid_metrics.begin(), valid_metrics.end(), [&](auto curr) { return metric != curr; }))
  {
    std::string metrics;
    for (auto curr : valid_metrics)
    {
      metrics += curr;
      metrics += ", ";
    }
    fprintf(stderr, "Expected one of [%s] got \"%s\" instead\n", metrics.c_str(), argv[4]);
    std::exit(1);
  }
}

int main(int argc, char* argv[])
{
  validate(argc, argv);

  std::string data_in = argv[1];
  std::string method = argv[2];
  int times = atoi(argv[3]);
  std::string metric = argv[4];
  std::string output = argv[5];

  try
  {
    if (method == "af_cpu")
    {
      af::setBackend(AF_BACKEND_CPU);
    }
    else if (method == "af_oneapi")
    {
      af::setBackend(AF_BACKEND_ONEAPI);
    }
    else if (method == "af_opencl")
    {
      af::setBackend(AF_BACKEND_OPENCL);
    }
  }
  catch (af::exception& e)
  {
    fprintf(stderr, "Caught exception when trying to set af backend\n");
    fprintf(stderr, "%s\n", e.what());
    throw;
  }

  rapidcsv::Document doc;

  try
  {
    doc = rapidcsv::Document(data_in, rapidcsv::LabelParams(0, 0));
  }
  catch (std::exception e)
  {
    fprintf(stderr, "Caught exception when trying to create csv reader\n");
    fprintf(stderr, "%s\n", e.what());
  }
  int col_count = doc.GetColumnCount() - 1;
  int row_count = doc.GetRowCount() - 1;
  std::vector<double> data_vec;
  data_vec.reserve(col_count * row_count);
  for (int i = 1; i < col_count; ++i)
  {
    auto curr = doc.GetColumn<double>(i);
    data_vec.insert(data_vec.end(), curr.begin(), curr.end());
  }
  const double* data = data_vec.data();

  std::vector<double> measurements;

  if (method == "af_cpu" || method == "af_oneapi" || method == "af_opencl")
  {
    af::array a = af::array(row_count, col_count, data);
    if (metric == "euclid")
    {
      measurements = iterate(times, [&]() { af_eucl_dist1(a); });
    }
    else
    {
      measurements = iterate(times, [&]() { af_pearson_dist(a); });
    }
  }
  else
  {
    arma::mat a = arma::mat(data, row_count, col_count);
    if (metric == "euclid")
    {
      measurements = iterate(times, [&]() { arma_dist_euclid(a); });
    }
    else
    {
      measurements = iterate(times, [&]() { arma_dist_pearson(a); });
    }
  }
  arma::vec measure_vec(measurements);
  double mean = arma::mean(measure_vec);
  double max = arma::max(measure_vec);
  double stddev = arma::stddev(measure_vec);
  std::cout << mean << " " << stddev << " " << max;
  std::fstream out(output, std::fstream::out);
  for (size_t i = 0; i < measurements.size(); ++i)
  {
    std::cout << " " << measurements[i];
    out << measurements[i];
    if (i + 1 != measurements.size())
    {
      out << ',';
    }
  }
  out.close();
  std::cout << std::endl;
}
